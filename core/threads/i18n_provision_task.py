"""
Background task that provisions missing language packages for a DB connection.
"""

from __future__ import annotations

from qgis.core import QgsTask
from qgis.PyQt.QtCore import pyqtSignal

from .task import GwTask
from ...libs import tools_log
from ..admin.i18n.i18n_language_service import (
    LocaleRequirement,
    ProvisionResult,
    get_available_versions,
    locales_to_download,
    provision_language_packages,
)

# Keep download attempts within the provision dialog wall-clock limit.
_PROVISION_DOWNLOAD_TIMEOUT_S = 20


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
            if self.isCanceled():
                return False

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
                should_abort=self.isCanceled,
                download_timeout=_PROVISION_DOWNLOAD_TIMEOUT_S,
            )
            self.result.requirements = requirements
            self.setProgress(100)
            if self.isCanceled():
                return False
            return self.result.ok
        except Exception as exc:
            self.exception = exc
            self._error = str(exc)
            if not self.result.failed:
                self.result.failed.append(("*", self._error))
            return False

    def cancel(self) -> None:
        # No aux DB connection — skip GwTask.cancel() PID cleanup.
        msg = "Task '{0}' was cancelled"
        msg_params = (self.description(),)
        tools_log.log_info(msg, msg_params=msg_params)
        QgsTask.cancel(self)

    def finished(self, result: bool) -> None:
        super().finished(result)
        self.setProgress(100)
        self.task_finished.emit(self.result)
