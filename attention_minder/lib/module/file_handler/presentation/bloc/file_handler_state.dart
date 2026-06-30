part of 'file_handler_bloc.dart';

abstract class FileHandlerState {}

class FileHandlerInitial extends FileHandlerState {}

class FileHandlerLoading extends FileHandlerState {}

class FilesLoadedSuccess extends FileHandlerState {
  final List<VideoFile> filesData;

  FilesLoadedSuccess({required this.filesData});
}

class FeedbackSavedSuccess extends FileHandlerState {
  final String message;

  FeedbackSavedSuccess({required this.message});
}

class FileHandlerError extends FileHandlerState {
  final String errorMessage;

  FileHandlerError({required this.errorMessage});
}
