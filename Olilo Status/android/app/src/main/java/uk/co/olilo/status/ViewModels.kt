package uk.co.olilo.status

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

class StatusViewModel(
    private val repository: StatusRepository = StatusRepository(),
) : ViewModel() {
    private val _state = MutableStateFlow(StatusScreenState())
    val state: StateFlow<StatusScreenState> = _state.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        viewModelScope.launch {
            runCatching { repository.fetchStatus() }
                .onSuccess { _state.value = it }
                .onFailure { error ->
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

    init {
        refresh()
    }

    fun refresh() {
        _state.update { it.copy(isLoading = true, errorMessage = null) }
        viewModelScope.launch {
            runCatching { repository.fetchNotices() }
                .onSuccess { next -> _state.update { next.copy(selectedKind = it.selectedKind) } }
                .onFailure { error ->
                    _state.update {
                        it.copy(
                            isLoading = false,
                            errorMessage = error.localizedMessage ?: "Unable to load notices.",
                        )
                    }
                }
        }
    }

    fun selectKind(kind: NoticeKind?) {
        _state.update { it.copy(selectedKind = kind) }
    }
}
