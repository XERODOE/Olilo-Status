package uk.co.olilo.status.main

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import uk.co.olilo.status.status.NoticeKind
import uk.co.olilo.status.status.NoticesScreenState
import uk.co.olilo.status.status.StatusRepository
import uk.co.olilo.status.status.StatusScreenState

class StatusViewModel(
    private val repository: StatusRepository = StatusRepository(),
) : ViewModel() {
    private val _state = MutableStateFlow(StatusScreenState())
    val state: StateFlow<StatusScreenState> = _state.asStateFlow()
    private var refreshJob: Job? = null

    init {
        refresh()
    }

    /** Reloads the status screen state, cancelling any in-flight refresh first. */
    fun refresh() {
        refreshJob?.cancel()
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        refreshJob = viewModelScope.launch {
            runCatching { repository.fetchStatus() }
                .onSuccess { _state.value = it }
                .onFailure { error ->
                    if (error is CancellationException) return@launch
                    _state.update {
                        it.copy(
                            isLoading = false,
                            errorMessage = error.localizedMessage ?: "Unable to load status.",
                        )
                    }
                }
        }
    }
}

class NoticesViewModel(
    private val repository: StatusRepository = StatusRepository(),
) : ViewModel() {
    private val _state = MutableStateFlow(NoticesScreenState())
    val state: StateFlow<NoticesScreenState> = _state.asStateFlow()
    private var refreshJob: Job? = null

    init {
        refresh()
    }

    /** Reloads notices while preserving the currently selected filter. */
    fun refresh() {
        refreshJob?.cancel()
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        refreshJob = viewModelScope.launch {
            runCatching { repository.fetchNotices() }
                .onSuccess { next -> _state.update { next.copy(selectedKind = it.selectedKind) } }
                .onFailure { error ->
                    if (error is CancellationException) return@launch
                    _state.update {
                        it.copy(
                            isLoading = false,
                            errorMessage = error.localizedMessage ?: "Unable to load notices.",
                        )
                    }
                }
        }
    }

    /** Updates the active notice kind filter. */
    fun selectKind(kind: NoticeKind?) {
        _state.update { it.copy(selectedKind = kind) }
    }
}
