"""
Background task that provisions missing language packages for a DB connection.
"""

from __future__ import annotations

from qgis.PyQt.QtCore import pyqtSignal

from .task import GwTask
from ..admin.i18n_language_service import (
    LocaleRequirement,
    ProvisionResult,
    get_available_versions,
    locales_to_download,
    provision_language_packages,
)


class GwI18nProvisionTask(GwTask):
    """Download missing packages for pre-collected locale requirements."""

    task_finished = pyqtSignal(object)  # ProvisionResult

    def __init__(
        self,
        description: str = "Provision language files",
        *,
        requirements: list[LocaleRequirement] | None = None,
        pending: list[LocaleRequirement] | None = None,
    ):
        super().__init__(description)
        self.use_aux_conn = False
        self.result = ProvisionResult()
        self._error: str | None = None
        self._requirements = list(requirements or ())
        self._pending = list(pending or ())

    def run(self) -> bool:
        super().run()
        try:
            if self.isCanceled():
                return False

            self.setProgress(5)
            requirements = self._requirements
            self.result.requirements = requirements
            if self.isCanceled():
                return False

            versions = get_available_versions()
            candidates = self._pending or requirements
            pending = locales_to_download(candidates, available_versions=versions)

            if not pending:
                self.result.skipped = [req.locale for req in requirements]
                self.setProgress(100)
                return True

            def _progress(index: int, total: int, _locale: str) -> None:
                if total <= 0:
                    self.setProgress(100)
                    return
                # Reserve 5–95% for downloads.
                self.setProgress(5 + int(90 * index / total))

            self.result = provision_language_packages(
                pending,
                available_versions=versions,
                progress_cb=_progress,
            )
            self.result.requirements = requirements
            self.setProgress(100)
            return self.result.ok
        except Exception as exc:
            self.exception = exc
            self._error = str(exc)
            if not self.result.failed:
                self.result.failed.append(("*", self._error))
            return False

    def finished(self, result: bool) -> None:
        super().finished(result)
        self.setProgress(100)
        self.task_finished.emit(self.result)
