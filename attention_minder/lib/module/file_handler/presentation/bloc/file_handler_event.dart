part of 'file_handler_bloc.dart';

abstract class FileHandlerEvent {}

class FetchFilesEvent extends FileHandlerEvent {
  final bool isManagement;

  FetchFilesEvent({this.isManagement = true});
}

class SaveFeedbackEvent extends FileHandlerEvent {
  final String feedback;

  SaveFeedbackEvent({required this.feedback});
}
