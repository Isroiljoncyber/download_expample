import 'package:equatable/equatable.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

class ItemHolderEntity extends Equatable {
  String taskId;
  String name;
  String url;
  String savedDir;
  String fileSize;
  DownloadTaskStatus status;
  int progress;

  ItemHolderEntity({
    this.taskId = "",
    this.name = "",
    this.savedDir = "",
    this.url = "",
    this.fileSize = "",
    this.status = DownloadTaskStatus.undefined,
    this.progress = 0,
  });

  @override
  List<Object?> get props => [
        taskId,
        name,
        savedDir,
        fileSize,
        url,
        status,
        progress,
      ];
}
