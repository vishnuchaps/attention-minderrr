import 'package:attention_minder/module/file_handler/data/model/video_file_model.dart';
import 'package:attention_minder/module/file_handler/data/repository/ifile_handler_repository.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'file_handler_event.dart';
part 'file_handler_state.dart';

@injectable
class FileHandlerBloc extends Bloc<FileHandlerEvent, FileHandlerState> {
  final IFileHandlerRepository _fileHandlerRepository;

  FileHandlerBloc(this._fileHandlerRepository) : super(FileHandlerInitial()) {
    on<FetchFilesEvent>(_onFetchFiles);
    on<SaveFeedbackEvent>(_onSaveFeedback);
  }

  Future<void> _onFetchFiles(
    FetchFilesEvent event,
    Emitter<FileHandlerState> emit,
  ) async {
    emit(FileHandlerLoading());
    try {
      final responseMap = await _fileHandlerRepository.getFiles(
        isManagement: event.isManagement,
      );
      final videoFileResponse = VideoFileResponse.fromJson(responseMap);
      emit(FilesLoadedSuccess(filesData: videoFileResponse.data));
    } catch (e) {
      emit(FileHandlerError(errorMessage: e.toString()));
    }
  }

  Future<void> _onSaveFeedback(
    SaveFeedbackEvent event,
    Emitter<FileHandlerState> emit,
  ) async {
    emit(FileHandlerLoading());
    try {
      final response = await _fileHandlerRepository.saveFeedback(
        feedback: event.feedback,
      );
      emit(FeedbackSavedSuccess(
        message: response['message'] ?? 'Feedback saved successfully!',
      ));
    } catch (e) {
      emit(FileHandlerError(errorMessage: e.toString()));
    }
  }
}
