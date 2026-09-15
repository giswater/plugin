import traceback
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from ....libs import tools_db, tools_os
from ...ui.dialog import GwDialog
from ..task import GwTask


class GwParseInpTask(GwTask):
    def __init__(self, description: str, inp_file_path: Path, dialog: GwDialog) -> None:
        super().__init__(description)
        self.inp_file_path: Path = inp_file_path
        self.dialog: GwDialog = dialog
        self.log: list[str] = []

    def run(self) -> bool:
        super().run()
        try:
            swmm_api = tools_os.get_dep("swmm_api")
            section_labels = tools_os.get_dep("swmm_api.input_file.section_labels")
            read_inp_file = swmm_api.read_inp_file
            OPTIONS = section_labels.OPTIONS

            self.log.append("Reading INP file...")
            self.network = read_inp_file(self.inp_file_path)
            flow_units: str = self.network[OPTIONS].get('FLOW_UNITS')

            if flow_units not in ("LPS", "LPM", "CMS"):
                message: str = (
                    "Flow units should be in liters or cubic meters for importing. "
                    f"INP file units: {flow_units}"
                )
                raise ValueError(message)

            self.log.append("Analyzing catalogs...")

            self.catalogs: Catalogs = Catalogs.from_network_model(
                self.network, self.log, aux_conn=self.aux_conn, is_thread=True
            )

            return True
        except Exception as e:
            self.exception: str = traceback.format_exc()
            self.log.append(f"{e}")
            return False


@dataclass(frozen=True)
class Catalogs:
    """
    Represents the catalogs for each type of element in the INP file,
    with the best correspondence in the DB.
    If a INP file doesn't have a type of node, its property receives `None`.
    """

    db_arcs: dict[str, tuple[str, Optional[float], Optional[float | str], Optional[float], Optional[float]]]
    db_features: dict[str, tuple[str, str, Optional[str]]]
    db_materials: dict[str, float]
    db_nodes: dict[str, str]
    db_flwreg: Optional[dict[str, str]]
    inp_junctions: Optional[list[str]]
    inp_outfalls: Optional[list[str]]
    inp_dividers: Optional[list[str]]
    inp_storage: Optional[list[str]]
    inp_conduits: dict[tuple[str, Optional[float], Optional[float | str], Optional[float], Optional[float]], list[str]]
    inp_pumps: Optional[list[str]]
    inp_orifice: Optional[list[str]]
    inp_weir: Optional[list[str]]
    inp_outlet: Optional[list[str]]
    inp_subcatchments: Optional[list[tuple[str, str]]]
    roughness_catalog: Optional[list[float]]

    @classmethod
    def from_network_model(cls, wn, log: Optional[list[str]] = None, aux_conn=None, is_thread=False):
        section_labels = tools_os.get_dep("swmm_api.input_file.section_labels")
        sections = tools_os.get_dep("swmm_api.input_file.sections")
        JUNCTIONS = section_labels.JUNCTIONS
        OUTFALLS = section_labels.OUTFALLS
        DIVIDERS = section_labels.DIVIDERS
        STORAGE = section_labels.STORAGE
        CONDUITS = section_labels.CONDUITS
        PUMPS = section_labels.PUMPS
        ORIFICES = section_labels.ORIFICES
        WEIRS = section_labels.WEIRS
        OUTLETS = section_labels.OUTLETS
        XSECTIONS = section_labels.XSECTIONS
        SUBCATCHMENTS = section_labels.SUBCATCHMENTS
        Conduit = sections.Conduit
        CrossSection = sections.CrossSection

        def tofloat(x):
            return 0.0 if x is None else float(x)

        def _get_rows(sql):
            return tools_db.get_rows(sql, is_thread=is_thread, aux_conn=aux_conn)

        # Get node catalog from DB
        if log:
            log.append("Getting node catalog from DB...")
        rows = _get_rows("""
                SELECT n.id, f.epa_default
                FROM cat_node AS n
                JOIN cat_feature_node AS f ON (n.node_type = f.id)
            """)

        db_node_catalog: dict[str, str] = {}
        if rows:
            db_node_catalog = dict(
                sorted({_id: epa_default for _id, epa_default in rows}.items())
            )

        # Get arc catalog from DB
        if log:
            log.append("Getting arc catalog from DB...")
        rows = _get_rows("""
                SELECT id, shape, geom1, CASE WHEN shape = 'CUSTOM' THEN curve_id::text ELSE geom2::text END AS geom2, geom3, geom4
                FROM cat_arc
            """)

        db_arc_catalog: dict[str, tuple[str, Optional[float], Optional[float | str], Optional[float], Optional[float]]] = {}
        if rows:
            unsorted_dict = {
                _id: (str(shape), tofloat(geom1), tofloat(geom2) if shape != 'CUSTOM' else str(geom2), tofloat(geom3), tofloat(geom4)) for _id, shape, geom1, geom2, geom3, geom4 in rows
            }
            db_arc_catalog = dict(sorted(unsorted_dict.items()))

        # Get flwreg catalog from DB
        if log:
            log.append("Getting flwreg catalog from DB...")
        rows = _get_rows("""
                SELECT ce.id, ce.element_type
                FROM cat_element ce
                JOIN cat_feature cf ON (ce.element_type = cf.id)
                WHERE cf.feature_class = 'FRELEM'
            """)
        db_flwreg_catalog: dict[str, str] = {}
        if rows:
            unsorted_dict = {
                _id: flwreg_type for _id, flwreg_type in rows
            }
            db_flwreg_catalog = dict(sorted(unsorted_dict.items()))

        # Get roughness catalog
        if log:
            log.append("Getting roughness catalog from DB...")
        rows = _get_rows("""
                SELECT id, n
                FROM cat_material
            """)
        db_mat_roughness_cat: dict[str, float] = {}
        if rows:
            unsorted_dict = {
                _id: tofloat(roughness) for _id, roughness in rows
            }
            db_mat_roughness_cat = dict(sorted(unsorted_dict.items()))

        # Get feature catalog
        if log:
            log.append("Getting feature catalog from DB...")
        rows = _get_rows("""
                SELECT cf.id, cf.feature_class, cf.feature_type,
                       COALESCE(cfn.epa_default, cfa.epa_default, cfe.epa_default) AS epa_default
                FROM cat_feature cf
                LEFT JOIN cat_feature_node cfn ON cfn.id = cf.id
                LEFT JOIN cat_feature_arc cfa ON cfa.id = cf.id
                LEFT JOIN cat_feature_element cfe ON cfe.id = cf.id
                WHERE COALESCE(cf.active, TRUE) IS TRUE
            """)
        db_feat_cat: dict[str, tuple[str, str, Optional[str]]] = {}
        if rows:
            unsorted_dict = {
                _id: (feature_type, feature_class, epa_default)
                for _id, feature_class, feature_type, epa_default in rows
            }
            db_feat_cat = dict(sorted(unsorted_dict.items()))

        # Get possible catalogs of the network
        if log:
            log.append("Getting junction catalog from INP file...")
        junction_catalogs: Optional[list[str]] = (
            [
                _id
                for _id, epa_default in db_node_catalog.items()
                if epa_default == "JUNCTION"
            ]
            if JUNCTIONS in wn and len(wn[JUNCTIONS]) > 0
            else None
        )

        if log:
            log.append("Getting outfall catalog from INP file...")

        outfall_catalogs: Optional[list[str]] = (
            [
                _id
                for _id, epa_default in db_node_catalog.items()
                if epa_default == "OUTFALL"
            ]
            if OUTFALLS in wn and len(wn[OUTFALLS]) > 0
            else None
        )

        if log:
            log.append("Getting divider catalog from DB...")

        divider_catalogs: Optional[list[str]] = (
            [
                _id
                for _id, epa_default in db_node_catalog.items()
                if epa_default == "DIVIDER"
            ]
            if DIVIDERS in wn and len(wn[DIVIDERS]) > 0
            else None
        )

        if log:
            log.append("Getting storage catalog from DB...")

        storage_catalogs: Optional[list[str]] = (
            [
                _id
                for _id, epa_default in db_node_catalog.items()
                if epa_default == "STORAGE"
            ]
            if STORAGE in wn and len(wn[STORAGE]) > 0
            else None
        )

        if log:
            log.append("Getting conduit types catalog from INP file...")

        conduit_types = set()
        for _, xs in wn[XSECTIONS].items():
            xs: CrossSection
            shape = xs.shape
            geom1 = xs.height
            geom2 = xs.parameter_2
            geom3 = xs.parameter_3
            geom4 = xs.parameter_4
            # n_barrels = xs.n_barrels
            # culvert = xs.culvert
            # transect = xs.transect
            curve_name = xs.curve_name
            if shape == 'CUSTOM':
                geom2 = curve_name

            conduit_types.add((shape, geom1, geom2, geom3, geom4))

        if log:
            log.append("Getting conduit roughness from INP file...")

        conduit_roughness = set()
        for _, c in wn[CONDUITS].items():
            c: Conduit
            roughness = c.roughness
            conduit_roughness.add(roughness)

        roughness_catalog: Optional[list[float]] = [roughness for roughness in sorted(conduit_roughness)] if conduit_roughness else None

        if log:
            log.append("Getting conduit catalogs...")

        conduit_catalogs: dict[tuple[str, Optional[float], Optional[float | str], Optional[float], Optional[float]], list[str]] = {}
        for conduit_type in sorted(conduit_types):
            conduit_catalogs[conduit_type] = [
                _id for _id, dr_pair in db_arc_catalog.items() if dr_pair == conduit_type
            ]

        if log:
            log.append("Getting pump catalog from INP file...")

        pump_catalogs: Optional[list[str]] = [] if PUMPS in wn and len(wn[PUMPS]) > 0 else None

        if log:
            log.append("Getting orifice catalog from INP file...")

        orifice_catalogs: Optional[list[str]] = [] if ORIFICES in wn and len(wn[ORIFICES]) > 0 else None

        if log:
            log.append("Getting weir catalog from INP file...")

        weir_catalogs: Optional[list[str]] = [] if WEIRS in wn and len(wn[WEIRS]) > 0 else None

        if log:
            log.append("Getting outlet catalog from INP file...")

        outlet_catalogs: Optional[list[str]] = [] if OUTLETS in wn and len(wn[OUTLETS]) > 0 else None

        if log:
            log.append("Getting subcatchments from INP file...")

        inp_subcatchments: Optional[list[tuple[str, str]]] = [(f"{s.outlet}", f"{s.rain_gage}") for s in wn[SUBCATCHMENTS].values()] if SUBCATCHMENTS in wn else None

        return cls(
            db_arc_catalog,
            db_feat_cat,
            db_mat_roughness_cat,
            db_node_catalog,
            db_flwreg_catalog,
            junction_catalogs,
            outfall_catalogs,
            divider_catalogs,
            storage_catalogs,
            conduit_catalogs,
            pump_catalogs,
            orifice_catalogs,
            weir_catalogs,
            outlet_catalogs,
            inp_subcatchments,
            roughness_catalog,
        )
