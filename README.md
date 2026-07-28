<div align="center">
	<a href="https://www.giswater.org/">
		<picture>
		<img alt="Giswater logo" src="./icons/dialogs/136.png" height="128">
		</picture>
	</a>
	<h1>Giswater</h1>
	<a href="https://qgis.org/"><img src="https://img.shields.io/badge/qgis-3.34%20(LTR)%20-blue.svg?style=for-the-badge&logo=qgis&logoColor=white"></a>
  	<a href="https://www.python.org/"><img src="https://img.shields.io/badge/python-3.9-blue.svg?style=for-the-badge&logo=python&logoColor=white"></a>
	<a href="https://www.postgresql.org/"><img src="https://img.shields.io/badge/postgresql-9.5|16-blue.svg?style=for-the-badge&logo=postgresql&logoColor=white"></a>
	<a href="./LICENSE"><img alt="LICENSE" src="https://img.shields.io/github/license/giswater/plugin?style=for-the-badge"></a>
</div>

## Welcome to the Giswater Project - QGIS Plugin

Water management has traditionally been complex and costly, making it difficult to efficiently plan or control water supply networks without further investments. However, with the inception of Giswater in 2014, the first open-source software specifically designed for water supply and water management, this complexity is now manageable.

Giswater integrates various IT solutions and pre-existing databases, enabling high-performance management systems combined with hydraulic software such as EPANET and SWMM.

Giswater is the first open-source tool for integral water cycle management, created for city councils, municipal administrations, water and sewerage service providers, and hydraulic professionals. As a driver, it connects hydraulic analysis tools and spatial databases, allowing user access from any GIS. Compatible with EPANET, EPA SWMM, GIS, WMS, SCADA, and more, Giswater integrates seamlessly into water management entities’ ecosystems, amplifying their operational capabilities.

Additionally, Giswater can be connected with business management tools like ERP, CRM, Business Intelligence software, and corporate mobile devices.

Developed in Python (QGIS plugin) and PL/SQL (PostgreSQL database), the project is organized across three main repositories: `QGIS-PLUGIN`, `DB-MODEL`, and `DOCS`.

---

## Table of Contents

1. [Requirements](#requirements)
2. [Install](#install)
3. [Test](#test)
4. [Deployment](#deployment)
5. [Wiki](#wiki)
6. [FAQ](#faqs)
7. [Code Repositories](#code-repositories)
8. [Versioning](#versioning)
9. [Third-Party Libraries](#third-party-libraries)
10. [License](#license)
11. [Acknowledgments](#acknowledgments)

---

## Requirements

To work with Giswater, you will need:

- **PostgreSQL**: Ensure to select the pgAdmin component (Database Manager) and PostGIS (Spatial Extension) during installation.
- **QGIS**: Required geoprocessing software.

## Install

Since Giswater functions as server-client software, installation is done across two environments.

### Backend Environment

Compatible with Windows, Mac, and Linux OS.

- Install PostgreSQL (versions 9.5 to 18).
- Install PostGIS, pgRouting, and other required PostgreSQL extensions (database-level, once per database):

  ```sql
  CREATE EXTENSION IF NOT EXISTS postgis;
  CREATE EXTENSION IF NOT EXISTS pgrouting;
  CREATE EXTENSION IF NOT EXISTS tablefunc;
  CREATE EXTENSION IF NOT EXISTS unaccent;
  CREATE EXTENSION IF NOT EXISTS postgis_raster;
  CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
  ```

  `postgis`, `pgrouting`, `tablefunc`, and `unaccent` are also created automatically when you build a WS/UD schema ([`dbmodel/schemas/main/common/base/init.sql`](dbmodel/schemas/main/common/base/init.sql)). Install the packages on the server first; the extension objects must exist at the OS level.

- **PostgreSQL roles** — Giswater uses a fixed role hierarchy. You do **not** need to run separate corporate DDL scripts: roles are created idempotently during schema creation and permissions are applied by `gw_fct_admin_role_permissions()` at the end of `lastprocess`.

  | Role | Purpose | Inherits |
  |------|---------|----------|
  | `role_basic` | Read-only base (`SELECT` on catalogued tables/views) | — |
  | `role_om` | Operations & maintenance | `role_basic` |
  | `role_edit` | Network editing | `role_om` |
  | `role_epa` | EPA / SWMM modelling | `role_edit` |
  | `role_plan` | Planning (psectors, etc.) | `role_epa` |
  | `role_admin` | Schema administration (no superuser) | `role_plan` |
  | `role_system` | Owns schema objects; used for DDL during build | `role_admin` |
  | `role_crm` | CRM integration (standalone, no inheritance chain) | — |

  Inheritance chain (each role is granted to the one below; higher roles inherit all lower permissions):

  ```
  role_system
    └── role_admin
          └── role_plan
                └── role_epa
                      └── role_edit
                            └── role_om
                                  └── role_basic

  role_crm   (standalone)
  ```

  **Installer requirements:** connect as a PostgreSQL superuser (or equivalent: `CREATEROLE` + `CREATE` on the target database). The build creates missing roles, (re)applies the role hierarchy on every schema create (`GRANT` is idempotent), grants `role_system` to the installer when superuser, creates the project schema `AUTHORIZATION role_system`, and runs restrictive grants (no blanket `ALL` on tables — see [`gw_fct_admin_role_permissions`](dbmodel/schemas/main/common/base/fct/gw_fct_admin_role_permissions.sql)).

  **Manual bootstrap** (only if you must prepare roles before the first schema build, e.g. restricted DBA workflow):

  ```sql
  DO $$
  DECLARE
    v_role_exists boolean;
  BEGIN
    SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_basic') INTO v_role_exists;
    IF NOT v_role_exists THEN
      CREATE ROLE role_basic NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;

    SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_om') INTO v_role_exists;
    IF NOT v_role_exists THEN
      CREATE ROLE role_om NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;

    SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_edit') INTO v_role_exists;
    IF NOT v_role_exists THEN
      CREATE ROLE role_edit NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;

    SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_epa') INTO v_role_exists;
    IF NOT v_role_exists THEN
      CREATE ROLE role_epa NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;

    SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_plan') INTO v_role_exists;
    IF NOT v_role_exists THEN
      CREATE ROLE role_plan NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;

    SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_admin') INTO v_role_exists;
    IF NOT v_role_exists THEN
      CREATE ROLE role_admin NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;

    SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_system') INTO v_role_exists;
    IF NOT v_role_exists THEN
      CREATE ROLE role_system NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;

    SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_crm') INTO v_role_exists;
    IF NOT v_role_exists THEN
      CREATE ROLE role_crm NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;

    GRANT role_basic TO role_om;
    GRANT role_om TO role_edit;
    GRANT role_edit TO role_epa;
    GRANT role_epa TO role_plan;
    GRANT role_plan TO role_admin;
    GRANT role_admin TO role_system;

    IF NOT pg_has_role(current_user, 'role_system', 'member')
       AND (SELECT rolsuper FROM pg_roles WHERE rolname = current_user) IS TRUE THEN
      GRANT role_system TO current_user;
    END IF;
  END$$;
  ```

  Map QGIS/PostgreSQL logins to the appropriate role (e.g. `GRANT role_edit TO gis_user`). Object-level grants on each project schema are (re)applied by `gw_fct_admin_role_permissions()` during create and upgrade (`lastprocess`).

### Frontend environment:

Compatible with Windows, Mac, and Linux, but EPA models are only supported on Windows.

- Install the latest Long-Term Release (LTR) of QGIS.
- Install SWMM (5.1) and EPANET (2.2). _Note_: EPA SWMM and EPANET may not work on Linux front-end environments.
- On Linux systems, you may need to install the PostgreSQL Qt driver for database connectivity.
  - On Ubuntu:
  ```
  sudo apt install libqt5sql5-psql
  ```
  - On Fedora:
  ```
  sudo dnf install qt5-qtbase-postgresql
  ```

## Test

**Database model (pgTAP, Docker):** [dbmodel/README.md — Testing](dbmodel/README.md#testing) — `./dbmodel/test/run_tests.sh ws` (PostgreSQL 16–18 via `PG_MAJOR`).

**Schema CLI (no QGIS):** [giswater_admin/README.md](giswater_admin/README.md) — `pipx install giswater-cli` then `gw create --kind ws …`

**Python unit tests:** `python3 -m pytest test/engine -v` (from plugin repo root).

Use the provided example projects, pre-loaded with datasets for testing. Find setup videos below:

- [Install the plugin](https://www.youtube.com/watch?v=EwDRoHY2qAk&list=PLQ-seRm9Djl4hxWuHidqYayHEk_wsKyko&index=4)
- [Setup connection](https://www.youtube.com/watch?v=LJGCUrqa0es&list=PLQ-seRm9Djl4hxWuHidqYayHEk_wsKyko&index=3)
- [Create DB schema example](https://www.youtube.com/watch?v=nR3PBtfGi9k&list=PLQ-seRm9Djl4hxWuHidqYayHEk_wsKyko&index=2)
- [Create QGIS project](https://www.youtube.com/watch?v=RwFumKKTB2k&list=PLQ-seRm9Djl4hxWuHidqYayHEk_wsKyko&index=1)

## Deployment

### Requirements

Ensure you have the permissions to connect to PostgreSQL and that your user has superuser rights for database administration tasks (e.g., creating schemas, roles, backups).

### Project Setup

- Define catalogs with at least the mandatory categories ([materials, node, arc]) and create map zones ([macroexploitation, exploitation, municipality, sector, dma]).
- To get started, refer to [Start from Scratch](https://github.com/giswater/plugin/wiki/Start-from-Scratch:-Installing-Giswater-and-steps-to-create-an-empty-project) for guidance.
- **Tip**: Once map zones and catalogs are defined, you can begin adding network nodes and arcs.

For more configuration options, see the [Giswater configuration guide](https://github.com/giswater/plugin/wiki/Config).

## Wiki

Explore additional documentation on the [Giswater Wiki](https://github.com/giswater/plugin/wiki).

## FAQs

Find answers to common questions in the [Giswater FAQs](https://github.com/giswater/plugin/wiki/FAQs).

## Code Repositories

- **Docs**: [Documentation repository](https://github.com/giswater/docs)
- **QGIS Plugin**: [QGIS Plugin repository](https://github.com/giswater/plugin)
- **Database Model**: [Database Model repository](https://github.com/giswater/giswater_dbmodel) — in this repo: [dbmodel/](dbmodel/) ([schema layout](dbmodel/README.md#schema-architecture), [local tests](dbmodel/README.md#testing))
- **Headless schema CLI**: [giswater_admin/](giswater_admin/) ([full reference](giswater_admin/README.md))

Other repositories may exist but are either deprecated or inactive.

## Versioning

Giswater follows a three-level release system:

- **Major**: New architecture with significant updates (no forward compatibility).
- **Minor**: Bug fixes and new features (forward compatible).
- **Build**: Minor fixes and updates (forward compatible).

Release frequency:

- **Build**: Monthly (12 builds/year)
- **Minor**: Annually
- **Major**: No fixed schedule

## Third-Party Libraries

Giswater uses the following third-party libraries:

- **WNTR**: [WNTR GitHub](https://github.com/USEPA/WNTR)
  WNTR is an open-source Python package for analyzing water distribution systems using hydraulic and water quality models.
  The WNTR license can be found in the [LICENSE](./packages/wntr/LICENSE.md) file or in their [repository](https://github.com/USEPA/WNTR/blob/main/LICENSE.md).

- **swmm-api**: [swmm-api GitLab](https://gitlab.com/markuspichler/swmm_api)
  swmm-api provides a Pythonic interface to the EPA SWMM5 software, enabling advanced scripting, simulation control, and access to simulation results.
  The license and further details can be found in the [LICENSE](./packages/swmm_api/LICENSE) or in their [repository](https://gitlab.com/markuspichler/swmm_api/-/blob/master/LICENSE).

- **tqdm**: [tqdm GitHub](https://github.com/tqdm/tqdm)
  tqdm is a fast, extensible progress bar library for Python, supporting console, GUI, and notebook environments.
  The tqdm license can be viewed in the [LICENSE](./packages/tqdm/LICENCE) or in their [repository](https://github.com/tqdm/tqdm/blob/master/LICENCE).

- **PyPDF2**: [PyPDF2 GitHub](https://github.com/py-pdf/pypdf)
  PyPDF2 is a Python library for working with PDF files, offering functionalities such as splitting, merging, and text extraction.
  The PyPDF2 license is available in the [LICENSE](./packages/PyPDF2/LICENSE) or in their [repository](https://github.com/py-pdf/pypdf/blob/main/LICENSE).

- **osmnx**: [OSMnx GitHub](https://github.com/gboeing/osmnx)
  OSMnx is a Python package to easily download, model, analyze, and visualize street networks and other geospatial features from OpenStreetMap. You can download and model walking, driving, or biking networks with a single line of code then analyze and visualize them. You can just as easily work with urban amenities/points of interest, building footprints, transit stops, elevation data, street orientations, speed/travel time, and routing.
  The OSMnx license can be viewed in the [LICENSE](./packages/osmnx/LICENSE.txt) or in their [repository](https://github.com/gboeing/osmnx/blob/main/LICENSE.txt)

## License

This program is free software, licensed under the GNU General Public License (GPL) version 3 or later. Refer to the [LICENSE](./LICENSE) file for details.

## Acknowledgments

Special thanks to our founding contributors:

- GITS-BarcelonaTech University
- Aigües de Mataró
- Cicle de l'Aigua del Ter S.A
- Aigües de Blanes
- Aigües del Prat
- Aigües de Vic
- Aigües de Castellbisbal
- Aigües de Banyoles
- Figueres de Serveis, S.A
- Prodaisa
- Sabemsa
- Consorci Aigües de Tarragona
- BGEO OPEN GIS S.L.
