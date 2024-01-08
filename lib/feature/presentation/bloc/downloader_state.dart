part of 'downloader_bloc.dart';

class DownloaderState extends Equatable {
  final List<ItemHolderEntity> items;
  final DownloadTaskStatus downloadAll;
  final String fileSize;

  const DownloaderState({
    this.items = const [],
    this.downloadAll = DownloadTaskStatus.undefined,
    this.fileSize = "",
  });

  DownloaderState copyWith({
    List<ItemHolderEntity>? items,
    DownloadTaskStatus? downloadAll,
    String? fileSize,
  }) {
    return DownloaderState(
      items: items ?? this.items,
      downloadAll: downloadAll ?? this.downloadAll,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  @override
  List<Object?> get props => [
        items,
        downloadAll,
        fileSize,
      ];
}
