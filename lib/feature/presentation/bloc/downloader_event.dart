part of 'downloader_bloc.dart';

@immutable
abstract class DownloaderEvent {}

class FileDownloadEvent extends DownloaderEvent {
  final ItemHolderEntity itemHolderEntity;

  FileDownloadEvent({required this.itemHolderEntity});
}

class CancelDownloadEvent extends DownloaderEvent {
  final ItemHolderEntity itemHolderEntity;

  CancelDownloadEvent({required this.itemHolderEntity});
}

class PauseDownloadEvent extends DownloaderEvent {
  final ItemHolderEntity itemHolderEntity;

  PauseDownloadEvent({required this.itemHolderEntity});
}

class ResumeDownloadEvent extends DownloaderEvent {
  final ItemHolderEntity itemHolderEntity;

  ResumeDownloadEvent({required this.itemHolderEntity});
}

class DownloadAllEvent extends DownloaderEvent {
  DownloadAllEvent();
}

class UpdateItems extends DownloaderEvent {
  final String taskId;
  final int progress;
  final DownloadTaskStatus status;

  UpdateItems({required this.taskId, required this.progress, required this.status});
}

class CancelDownloadAllEvent extends DownloaderEvent {
  CancelDownloadAllEvent();
}

class PauseDownloadAllEvent extends DownloaderEvent {
  PauseDownloadAllEvent();
}

class CalculateFileSizeEvent extends DownloaderEvent {
  CalculateFileSizeEvent();
}

class ResumeDownloadAllEvent extends DownloaderEvent {
  ResumeDownloadAllEvent();
}

class LoadFromDB extends DownloaderEvent {
  LoadFromDB();
}

class BindIsolate extends DownloaderEvent {
  BindIsolate();
}

class UnBindIsolate extends DownloaderEvent {
  UnBindIsolate();
}

class UpdateTaskId extends DownloaderEvent {
  final String oldTaskId;
  final String newTaskId;

  UpdateTaskId({required this.oldTaskId, required this.newTaskId});
}
