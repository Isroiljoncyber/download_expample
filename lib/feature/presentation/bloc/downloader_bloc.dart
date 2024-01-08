import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:download_expample/core/data.dart';
import 'package:download_expample/feature/domain/entites/item_holder_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

part 'downloader_event.dart';

part 'downloader_state.dart';

class DownloaderBloc extends Bloc<DownloaderEvent, DownloaderState> {
  DownloaderBloc() : super(DownloaderState(items: files)) {
    on<FileDownloadEvent>((event, emit) async {
      final task = event.itemHolderEntity;
      final savePath = await prepareSaveUrl(task.name);
      if (savePath.isNotEmpty) {
        await FlutterDownloader.enqueue(
          url: task.url,
          fileName: "${task.name}.${task.url.split(".").last}",
          headers: {'auth': 'test_for_sql_encoding'},
          savedDir: "$savePath/${task.name}",
          showNotification: true,
          openFileFromNotification: true,
        ).then((taskId) {
          state.items[state.items.indexOf(task)].taskId = taskId!;
          state.items[state.items.indexOf(task)].savedDir = "$savePath/${task.name}";
          state.items[state.items.indexOf(task)].name = "${task.name}.${task.url.split(".").last}";
          emit(DownloaderState(items: state.items));
          add(CalculateFileSizeEvent());
        });
      } else {
        /// TODO: handle error
        await _checkPermission();
      }
    });

    on<CalculateFileSizeEvent>((event, emit) async {
      // print("Calculating");
      // await totalSize(path).then((value) {
      //   final fileSize = formatBytes(value, 2);
      //   emit(state.copyWith(fileSize: fileSize));
      // });
    });

    on<LoadFromDB>((event, emit) async {
      final tasks = await FlutterDownloader.loadTasks();
      if (tasks == null || tasks.isEmpty) return;
      state.items.forEach((element) async {
        final nTask = tasks.where((task) => task.url == element.url).toList();
        await totalSize(element.savedDir).then((value) {
          final fileSize = formatBytes(value, 2);
          if (nTask.isEmpty) return;
          final nItem = ItemHolderEntity(
            name: element.name,
            savedDir: element.savedDir,
            taskId: nTask[0].taskId,
            url: element.url,
            status: nTask[0].status,
            progress: nTask[0].progress,
            fileSize: fileSize,
          );
          state.items[state.items.indexOf(element)] = nItem;
        });
      });
    });

    on<PauseDownloadEvent>((event, emit) async {
      final task = event.itemHolderEntity;
      await FlutterDownloader.pause(taskId: task.taskId);
    });

    on<DownloadAllEvent>((event, emit) async {
      state.copyWith(downloadAll: DownloadTaskStatus.running);
      for (var element in state.items) {
        add(FileDownloadEvent(itemHolderEntity: element));
      }
    });

    on<PauseDownloadAllEvent>((event, emit) async {
      state.copyWith(downloadAll: DownloadTaskStatus.paused);
      for (var element in state.items) {
        add(PauseDownloadEvent(itemHolderEntity: element));
      }
    });

    on<ResumeDownloadAllEvent>((event, emit) async {
      state.copyWith(downloadAll: DownloadTaskStatus.running);
      for (var element in state.items) {
        add(ResumeDownloadEvent(itemHolderEntity: element));
      }
    });

    on<ResumeDownloadEvent>((event, emit) async {
      final task = event.itemHolderEntity;
      final nTaskId = await FlutterDownloader.resume(taskId: task.taskId);
      add(UpdateTaskId(oldTaskId: task.taskId, newTaskId: nTaskId!));
    });

    /// Update only task id when it changes
    on<UpdateTaskId>((event, emit) async {
      List<ItemHolderEntity> nList = [...state.items];
      final task = nList.firstWhere((task) => task.taskId == event.oldTaskId);
      final nItem = ItemHolderEntity(
        taskId: event.newTaskId,
        name: task.name,
        savedDir: task.savedDir,
        status: task.status,
        url: task.url,
        progress: task.progress,
      );
      nList[nList.indexOf(task)] = nItem;
      emit(state.copyWith(items: nList));
    });

    on<BindIsolate>((event, emit) {
      final ReceivePort port = ReceivePort();
      final isSuccess = IsolateNameServer.registerPortWithName(
        port.sendPort,
        'downloader_send_port',
      );
      if (!isSuccess) {
        add(UnBindIsolate());
        add(BindIsolate());
        return;
      }
      port.listen((dynamic data) {
        final taskId = (data as List<dynamic>)[0] as String;
        final status = DownloadTaskStatus.fromInt(data[1] as int);
        final progress = data[2] as int;
        add(CalculateFileSizeEvent());
        add(UpdateItems(taskId: taskId, progress: progress, status: status));
      });
      FlutterDownloader.registerCallback(downloadCallback, step: 1);
    });

    on<UpdateItems>((event, emit) {
      List<ItemHolderEntity> nList = [...state.items];
      final task = nList.firstWhere((task) => task.taskId == event.taskId);
      final nItem = ItemHolderEntity(
        name: task.name,
        taskId: task.taskId,
        savedDir: task.savedDir,
        status: event.status,
        progress: event.progress,
        url: task.url,
      );
      nList[nList.indexOf(task)] = nItem;
      bool isDownloadAll = nList.every((element) => element.status == DownloadTaskStatus.complete);
      emit(state.copyWith(
          items: nList, downloadAll: isDownloadAll ? DownloadTaskStatus.complete : DownloadTaskStatus.running));
    });

    on<UnBindIsolate>((event, emit) async {
      IsolateNameServer.removePortNameMapping('downloader_send_port');
    });
  }

  /// TODO: implement event handler
  @pragma('vm:entry-point')
  static void downloadCallback(
    String id,
    int status,
    int progress,
  ) {
    IsolateNameServer.lookupPortByName('downloader_send_port')?.send([id, status, progress]);
  }

  String formatBytes(int bytes, int decimals) {
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    int unitIndex = 0;
    double value = bytes.toDouble();

    while (value >= 1024 && unitIndex < suffixes.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    return '${value.toStringAsFixed(decimals)} ${suffixes[unitIndex]}';
  }

  Future<String> prepareSaveUrl(String fileName) async {
    final permissionReady = await _checkPermission();
    if (permissionReady) {
      return await prepareSaveDir(fileName);
    } else {
      return '';
    }
  }

  Future<bool> _checkPermission() async {
    if (Platform.isIOS) {
      return true;
    }
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status == PermissionStatus.granted) {
        return true;
      }

      final result = await Permission.storage.request();
      return result == PermissionStatus.granted;
    }

    throw StateError('unknown platform');
  }

  Future<String> prepareSaveDir(String fileName) async {
    final localPath = (await _getSavedDir())!;
    final savedDir = Directory('$localPath/$fileName');
    if (!savedDir.existsSync()) {
      await savedDir.create();
    }
    return localPath;
  }

  Future<String?> _getSavedDir() async {
    String? externalStorageDirPath;
    externalStorageDirPath = (await getApplicationDocumentsDirectory()).absolute.path;
    return externalStorageDirPath;
  }

  Future<int> totalSize(String path) async {
    int size = 0;
    try {
      // final savePath = await prepareSaveUrl();
      final folder = Directory(path);
      if (await folder.exists()) {
        List<FileSystemEntity> entities = folder.listSync(recursive: true);
        for (FileSystemEntity entity in entities) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e) {
      print("Error calculating folder size: $e");
    }

    return size;
  }
}
