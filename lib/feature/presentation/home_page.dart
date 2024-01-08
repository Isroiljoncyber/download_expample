import 'package:download_expample/feature/presentation/bloc/downloader_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_file/open_file.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DownloaderBloc downloaderBloc;

  @override
  void initState() {
    super.initState();
    downloaderBloc = DownloaderBloc()
      ..add(LoadFromDB())
      ..add(BindIsolate())
      ..add(CalculateFileSizeEvent());
  }

  @override
  void dispose() {
    super.dispose();
    downloaderBloc
      ..add(UnBindIsolate())
      ..close();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: downloaderBloc,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Text('Downloader Demo'),
          actions: [
            Text("FileSize: ${downloaderBloc.state.fileSize}"),
            BlocBuilder<DownloaderBloc, DownloaderState>(
              builder: (context, state) {
                return IconButton(
                  onPressed: () {
                    if (state.downloadAll == DownloadTaskStatus.undefined) {
                      downloaderBloc.add(DownloadAllEvent());
                    } else if (state.downloadAll == DownloadTaskStatus.running) {
                      downloaderBloc.add(PauseDownloadAllEvent());
                    } else if (state.downloadAll == DownloadTaskStatus.paused) {
                      downloaderBloc.add(ResumeDownloadAllEvent());
                    }
                  },
                  icon: downloadStatus(state.downloadAll),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<DownloaderBloc, DownloaderState>(
          builder: (context, state) {
            return ListView.separated(
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return ListTile(
                  onTap: () {
                    if (item.status == DownloadTaskStatus.undefined) {
                      downloaderBloc.add(FileDownloadEvent(itemHolderEntity: item));
                    } else if (item.status == DownloadTaskStatus.running) {
                      downloaderBloc.add(PauseDownloadEvent(itemHolderEntity: item));
                    } else if (item.status == DownloadTaskStatus.paused) {
                      downloaderBloc.add(ResumeDownloadEvent(itemHolderEntity: item));
                    } else if (item.status == DownloadTaskStatus.complete) {
                      final file = "${item.savedDir}/${item.name}.${item.url.split(".").last}";
                      OpenFile.open(file);
                    } else if (item.status == DownloadTaskStatus.canceled) {
                      downloaderBloc.add(FileDownloadEvent(itemHolderEntity: item));
                    } else if (item.status == DownloadTaskStatus.failed) {
                      downloaderBloc.add(FileDownloadEvent(itemHolderEntity: item));
                    }
                  },
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.items[index].name),
                      Text(state.items[index].savedDir),
                      Text(state.items[index].fileSize),
                    ],
                  ),
                  leading: downloadStatus(item.status),
                  trailing: Text(
                    "${item.progress} %",
                    style: const TextStyle(color: Colors.green, fontSize: 16),
                  ),
                  subtitle: (item.status == DownloadTaskStatus.running || item.status == DownloadTaskStatus.paused)
                      ? LinearProgressIndicator(
                          color: Colors.green,
                          value: item.progress / 100,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        )
                      : null,
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return const Divider();
              },
            );
          },
        ),
      ),
    );
  }

  Icon downloadStatus(DownloadTaskStatus status) {
    return status == DownloadTaskStatus.undefined
        ? const Icon(Icons.file_download, color: Colors.green)
        : status == DownloadTaskStatus.complete
            ? const Icon(
                Icons.done,
                color: Colors.green,
              )
            : status == DownloadTaskStatus.paused
                ? const Icon(Icons.play_arrow, color: Colors.green)
                : status == DownloadTaskStatus.running
                    ? const Icon(Icons.pause, color: Colors.yellow)
                    : status == DownloadTaskStatus.canceled
                        ? const Icon(Icons.cancel, color: Colors.red)
                        : status == DownloadTaskStatus.enqueued
                            ? const Icon(Icons.access_time_rounded, color: Colors.yellow)
                            : const Icon(Icons.error, color: Colors.red);
  }
}
