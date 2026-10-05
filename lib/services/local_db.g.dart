// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_db.dart';

// ignore_for_file: type=lint
class $PendingTrialsTable extends PendingTrials with TableInfo<$PendingTrialsTable, PendingTrial> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingTrialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(SyncStatus.pending),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    remoteId,
    operation,
    payloadJson,
    syncStatus,
    errorMessage,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_trials';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingTrial> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta, localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(data['payload_json']!, _payloadJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(data['error_message']!, _errorMessageMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  PendingTrial map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingTrial(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_id'],
      ),
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PendingTrialsTable createAlias(String alias) {
    return $PendingTrialsTable(attachedDatabase, alias);
  }
}

class PendingTrial extends DataClass implements Insertable<PendingTrial> {
  final String localId;
  final int? remoteId;
  final String operation;
  final String payloadJson;
  final String syncStatus;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PendingTrial({
    required this.localId,
    this.remoteId,
    required this.operation,
    required this.payloadJson,
    required this.syncStatus,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PendingTrialsCompanion toCompanion(bool nullToAbsent) {
    return PendingTrialsCompanion(
      localId: Value(localId),
      remoteId: remoteId == null && nullToAbsent ? const Value.absent() : Value(remoteId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      syncStatus: Value(syncStatus),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PendingTrial.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingTrial(
      localId: serializer.fromJson<String>(json['localId']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'remoteId': serializer.toJson<int?>(remoteId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PendingTrial copyWith({
    String? localId,
    Value<int?> remoteId = const Value.absent(),
    String? operation,
    String? payloadJson,
    String? syncStatus,
    Value<String?> errorMessage = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PendingTrial(
    localId: localId ?? this.localId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    syncStatus: syncStatus ?? this.syncStatus,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PendingTrial copyWithCompanion(PendingTrialsCompanion data) {
    return PendingTrial(
      localId: data.localId.present ? data.localId.value : this.localId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      syncStatus: data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      errorMessage: data.errorMessage.present ? data.errorMessage.value : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingTrial(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    remoteId,
    operation,
    payloadJson,
    syncStatus,
    errorMessage,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingTrial &&
          other.localId == this.localId &&
          other.remoteId == this.remoteId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.syncStatus == this.syncStatus &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PendingTrialsCompanion extends UpdateCompanion<PendingTrial> {
  final Value<String> localId;
  final Value<int?> remoteId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<String> syncStatus;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PendingTrialsCompanion({
    this.localId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingTrialsCompanion.insert({
    required String localId,
    this.remoteId = const Value.absent(),
    required String operation,
    required String payloadJson,
    this.syncStatus = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       operation = Value(operation),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PendingTrial> custom({
    Expression<String>? localId,
    Expression<int>? remoteId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<String>? syncStatus,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (remoteId != null) 'remote_id': remoteId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingTrialsCompanion copyWith({
    Value<String>? localId,
    Value<int?>? remoteId,
    Value<String>? operation,
    Value<String>? payloadJson,
    Value<String>? syncStatus,
    Value<String?>? errorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PendingTrialsCompanion(
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      syncStatus: syncStatus ?? this.syncStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingTrialsCompanion(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingFilesTable extends PendingFiles with TableInfo<$PendingFilesTable, PendingFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trialLocalIdMeta = const VerificationMeta('trialLocalId');
  @override
  late final GeneratedColumn<String> trialLocalId = GeneratedColumn<String>(
    'trial_local_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trialRemoteIdMeta = const VerificationMeta('trialRemoteId');
  @override
  late final GeneratedColumn<int> trialRemoteId = GeneratedColumn<int>(
    'trial_remote_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalNameMeta = const VerificationMeta('originalName');
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
    'original_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localFilePathMeta = const VerificationMeta('localFilePath');
  @override
  late final GeneratedColumn<String> localFilePath = GeneratedColumn<String>(
    'local_file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uploadStatusMeta = const VerificationMeta('uploadStatus');
  @override
  late final GeneratedColumn<String> uploadStatus = GeneratedColumn<String>(
    'upload_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(SyncStatus.pending),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trialLocalId,
    trialRemoteId,
    category,
    originalName,
    mimeType,
    localFilePath,
    fileSizeBytes,
    uploadStatus,
    errorMessage,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trial_local_id')) {
      context.handle(
        _trialLocalIdMeta,
        trialLocalId.isAcceptableOrUnknown(data['trial_local_id']!, _trialLocalIdMeta),
      );
    }
    if (data.containsKey('trial_remote_id')) {
      context.handle(
        _trialRemoteIdMeta,
        trialRemoteId.isAcceptableOrUnknown(data['trial_remote_id']!, _trialRemoteIdMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('original_name')) {
      context.handle(
        _originalNameMeta,
        originalName.isAcceptableOrUnknown(data['original_name']!, _originalNameMeta),
      );
    } else if (isInserting) {
      context.missing(_originalNameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('local_file_path')) {
      context.handle(
        _localFilePathMeta,
        localFilePath.isAcceptableOrUnknown(data['local_file_path']!, _localFilePathMeta),
      );
    } else if (isInserting) {
      context.missing(_localFilePathMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(data['file_size_bytes']!, _fileSizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('upload_status')) {
      context.handle(
        _uploadStatusMeta,
        uploadStatus.isAcceptableOrUnknown(data['upload_status']!, _uploadStatusMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(data['error_message']!, _errorMessageMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingFile(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      trialLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trial_local_id'],
      ),
      trialRemoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trial_remote_id'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      originalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_name'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      localFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_file_path'],
      )!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      )!,
      uploadStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingFilesTable createAlias(String alias) {
    return $PendingFilesTable(attachedDatabase, alias);
  }
}

class PendingFile extends DataClass implements Insertable<PendingFile> {
  final String id;
  final String? trialLocalId;
  final int? trialRemoteId;
  final String category;
  final String originalName;
  final String? mimeType;
  final String localFilePath;
  final int fileSizeBytes;
  final String uploadStatus;
  final String? errorMessage;
  final DateTime createdAt;
  const PendingFile({
    required this.id,
    this.trialLocalId,
    this.trialRemoteId,
    required this.category,
    required this.originalName,
    this.mimeType,
    required this.localFilePath,
    required this.fileSizeBytes,
    required this.uploadStatus,
    this.errorMessage,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || trialLocalId != null) {
      map['trial_local_id'] = Variable<String>(trialLocalId);
    }
    if (!nullToAbsent || trialRemoteId != null) {
      map['trial_remote_id'] = Variable<int>(trialRemoteId);
    }
    map['category'] = Variable<String>(category);
    map['original_name'] = Variable<String>(originalName);
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    map['local_file_path'] = Variable<String>(localFilePath);
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    map['upload_status'] = Variable<String>(uploadStatus);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingFilesCompanion toCompanion(bool nullToAbsent) {
    return PendingFilesCompanion(
      id: Value(id),
      trialLocalId: trialLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(trialLocalId),
      trialRemoteId: trialRemoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(trialRemoteId),
      category: Value(category),
      originalName: Value(originalName),
      mimeType: mimeType == null && nullToAbsent ? const Value.absent() : Value(mimeType),
      localFilePath: Value(localFilePath),
      fileSizeBytes: Value(fileSizeBytes),
      uploadStatus: Value(uploadStatus),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
    );
  }

  factory PendingFile.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingFile(
      id: serializer.fromJson<String>(json['id']),
      trialLocalId: serializer.fromJson<String?>(json['trialLocalId']),
      trialRemoteId: serializer.fromJson<int?>(json['trialRemoteId']),
      category: serializer.fromJson<String>(json['category']),
      originalName: serializer.fromJson<String>(json['originalName']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      localFilePath: serializer.fromJson<String>(json['localFilePath']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      uploadStatus: serializer.fromJson<String>(json['uploadStatus']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'trialLocalId': serializer.toJson<String?>(trialLocalId),
      'trialRemoteId': serializer.toJson<int?>(trialRemoteId),
      'category': serializer.toJson<String>(category),
      'originalName': serializer.toJson<String>(originalName),
      'mimeType': serializer.toJson<String?>(mimeType),
      'localFilePath': serializer.toJson<String>(localFilePath),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'uploadStatus': serializer.toJson<String>(uploadStatus),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingFile copyWith({
    String? id,
    Value<String?> trialLocalId = const Value.absent(),
    Value<int?> trialRemoteId = const Value.absent(),
    String? category,
    String? originalName,
    Value<String?> mimeType = const Value.absent(),
    String? localFilePath,
    int? fileSizeBytes,
    String? uploadStatus,
    Value<String?> errorMessage = const Value.absent(),
    DateTime? createdAt,
  }) => PendingFile(
    id: id ?? this.id,
    trialLocalId: trialLocalId.present ? trialLocalId.value : this.trialLocalId,
    trialRemoteId: trialRemoteId.present ? trialRemoteId.value : this.trialRemoteId,
    category: category ?? this.category,
    originalName: originalName ?? this.originalName,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    localFilePath: localFilePath ?? this.localFilePath,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    uploadStatus: uploadStatus ?? this.uploadStatus,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingFile copyWithCompanion(PendingFilesCompanion data) {
    return PendingFile(
      id: data.id.present ? data.id.value : this.id,
      trialLocalId: data.trialLocalId.present ? data.trialLocalId.value : this.trialLocalId,
      trialRemoteId: data.trialRemoteId.present ? data.trialRemoteId.value : this.trialRemoteId,
      category: data.category.present ? data.category.value : this.category,
      originalName: data.originalName.present ? data.originalName.value : this.originalName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      localFilePath: data.localFilePath.present ? data.localFilePath.value : this.localFilePath,
      fileSizeBytes: data.fileSizeBytes.present ? data.fileSizeBytes.value : this.fileSizeBytes,
      uploadStatus: data.uploadStatus.present ? data.uploadStatus.value : this.uploadStatus,
      errorMessage: data.errorMessage.present ? data.errorMessage.value : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingFile(')
          ..write('id: $id, ')
          ..write('trialLocalId: $trialLocalId, ')
          ..write('trialRemoteId: $trialRemoteId, ')
          ..write('category: $category, ')
          ..write('originalName: $originalName, ')
          ..write('mimeType: $mimeType, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trialLocalId,
    trialRemoteId,
    category,
    originalName,
    mimeType,
    localFilePath,
    fileSizeBytes,
    uploadStatus,
    errorMessage,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingFile &&
          other.id == this.id &&
          other.trialLocalId == this.trialLocalId &&
          other.trialRemoteId == this.trialRemoteId &&
          other.category == this.category &&
          other.originalName == this.originalName &&
          other.mimeType == this.mimeType &&
          other.localFilePath == this.localFilePath &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.uploadStatus == this.uploadStatus &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt);
}

class PendingFilesCompanion extends UpdateCompanion<PendingFile> {
  final Value<String> id;
  final Value<String?> trialLocalId;
  final Value<int?> trialRemoteId;
  final Value<String> category;
  final Value<String> originalName;
  final Value<String?> mimeType;
  final Value<String> localFilePath;
  final Value<int> fileSizeBytes;
  final Value<String> uploadStatus;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PendingFilesCompanion({
    this.id = const Value.absent(),
    this.trialLocalId = const Value.absent(),
    this.trialRemoteId = const Value.absent(),
    this.category = const Value.absent(),
    this.originalName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingFilesCompanion.insert({
    required String id,
    this.trialLocalId = const Value.absent(),
    this.trialRemoteId = const Value.absent(),
    required String category,
    required String originalName,
    this.mimeType = const Value.absent(),
    required String localFilePath,
    required int fileSizeBytes,
    this.uploadStatus = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       originalName = Value(originalName),
       localFilePath = Value(localFilePath),
       fileSizeBytes = Value(fileSizeBytes),
       createdAt = Value(createdAt);
  static Insertable<PendingFile> custom({
    Expression<String>? id,
    Expression<String>? trialLocalId,
    Expression<int>? trialRemoteId,
    Expression<String>? category,
    Expression<String>? originalName,
    Expression<String>? mimeType,
    Expression<String>? localFilePath,
    Expression<int>? fileSizeBytes,
    Expression<String>? uploadStatus,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trialLocalId != null) 'trial_local_id': trialLocalId,
      if (trialRemoteId != null) 'trial_remote_id': trialRemoteId,
      if (category != null) 'category': category,
      if (originalName != null) 'original_name': originalName,
      if (mimeType != null) 'mime_type': mimeType,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (uploadStatus != null) 'upload_status': uploadStatus,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingFilesCompanion copyWith({
    Value<String>? id,
    Value<String?>? trialLocalId,
    Value<int?>? trialRemoteId,
    Value<String>? category,
    Value<String>? originalName,
    Value<String?>? mimeType,
    Value<String>? localFilePath,
    Value<int>? fileSizeBytes,
    Value<String>? uploadStatus,
    Value<String?>? errorMessage,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PendingFilesCompanion(
      id: id ?? this.id,
      trialLocalId: trialLocalId ?? this.trialLocalId,
      trialRemoteId: trialRemoteId ?? this.trialRemoteId,
      category: category ?? this.category,
      originalName: originalName ?? this.originalName,
      mimeType: mimeType ?? this.mimeType,
      localFilePath: localFilePath ?? this.localFilePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (trialLocalId.present) {
      map['trial_local_id'] = Variable<String>(trialLocalId.value);
    }
    if (trialRemoteId.present) {
      map['trial_remote_id'] = Variable<int>(trialRemoteId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (localFilePath.present) {
      map['local_file_path'] = Variable<String>(localFilePath.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (uploadStatus.present) {
      map['upload_status'] = Variable<String>(uploadStatus.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingFilesCompanion(')
          ..write('id: $id, ')
          ..write('trialLocalId: $trialLocalId, ')
          ..write('trialRemoteId: $trialRemoteId, ')
          ..write('category: $category, ')
          ..write('originalName: $originalName, ')
          ..write('mimeType: $mimeType, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDb extends GeneratedDatabase {
  _$LocalDb(QueryExecutor e) : super(e);
  $LocalDbManager get managers => $LocalDbManager(this);
  late final $PendingTrialsTable pendingTrials = $PendingTrialsTable(this);
  late final $PendingFilesTable pendingFiles = $PendingFilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [pendingTrials, pendingFiles];
}

typedef $$PendingTrialsTableCreateCompanionBuilder =
    PendingTrialsCompanion Function({
      required String localId,
      Value<int?> remoteId,
      required String operation,
      required String payloadJson,
      Value<String> syncStatus,
      Value<String?> errorMessage,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PendingTrialsTableUpdateCompanionBuilder =
    PendingTrialsCompanion Function({
      Value<String> localId,
      Value<int?> remoteId,
      Value<String> operation,
      Value<String> payloadJson,
      Value<String> syncStatus,
      Value<String?> errorMessage,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PendingTrialsTableFilterComposer extends Composer<_$LocalDb, $PendingTrialsTable> {
  $$PendingTrialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson =>
      $composableBuilder(column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PendingTrialsTableOrderingComposer extends Composer<_$LocalDb, $PendingTrialsTable> {
  $$PendingTrialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson =>
      $composableBuilder(column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PendingTrialsTableAnnotationComposer extends Composer<_$LocalDb, $PendingTrialsTable> {
  $$PendingTrialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson =>
      $composableBuilder(column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<String> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PendingTrialsTableTableManager
    extends
        RootTableManager<
          _$LocalDb,
          $PendingTrialsTable,
          PendingTrial,
          $$PendingTrialsTableFilterComposer,
          $$PendingTrialsTableOrderingComposer,
          $$PendingTrialsTableAnnotationComposer,
          $$PendingTrialsTableCreateCompanionBuilder,
          $$PendingTrialsTableUpdateCompanionBuilder,
          (PendingTrial, BaseReferences<_$LocalDb, $PendingTrialsTable, PendingTrial>),
          PendingTrial,
          PrefetchHooks Function()
        > {
  $$PendingTrialsTableTableManager(_$LocalDb db, $PendingTrialsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PendingTrialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingTrialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingTrialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<int?> remoteId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingTrialsCompanion(
                localId: localId,
                remoteId: remoteId,
                operation: operation,
                payloadJson: payloadJson,
                syncStatus: syncStatus,
                errorMessage: errorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<int?> remoteId = const Value.absent(),
                required String operation,
                required String payloadJson,
                Value<String> syncStatus = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingTrialsCompanion.insert(
                localId: localId,
                remoteId: remoteId,
                operation: operation,
                payloadJson: payloadJson,
                syncStatus: syncStatus,
                errorMessage: errorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingTrialsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDb,
      $PendingTrialsTable,
      PendingTrial,
      $$PendingTrialsTableFilterComposer,
      $$PendingTrialsTableOrderingComposer,
      $$PendingTrialsTableAnnotationComposer,
      $$PendingTrialsTableCreateCompanionBuilder,
      $$PendingTrialsTableUpdateCompanionBuilder,
      (PendingTrial, BaseReferences<_$LocalDb, $PendingTrialsTable, PendingTrial>),
      PendingTrial,
      PrefetchHooks Function()
    >;
typedef $$PendingFilesTableCreateCompanionBuilder =
    PendingFilesCompanion Function({
      required String id,
      Value<String?> trialLocalId,
      Value<int?> trialRemoteId,
      required String category,
      required String originalName,
      Value<String?> mimeType,
      required String localFilePath,
      required int fileSizeBytes,
      Value<String> uploadStatus,
      Value<String?> errorMessage,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PendingFilesTableUpdateCompanionBuilder =
    PendingFilesCompanion Function({
      Value<String> id,
      Value<String?> trialLocalId,
      Value<int?> trialRemoteId,
      Value<String> category,
      Value<String> originalName,
      Value<String?> mimeType,
      Value<String> localFilePath,
      Value<int> fileSizeBytes,
      Value<String> uploadStatus,
      Value<String?> errorMessage,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PendingFilesTableFilterComposer extends Composer<_$LocalDb, $PendingFilesTable> {
  $$PendingFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trialLocalId =>
      $composableBuilder(column: $table.trialLocalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trialRemoteId =>
      $composableBuilder(column: $table.trialRemoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalName =>
      $composableBuilder(column: $table.originalName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localFilePath =>
      $composableBuilder(column: $table.localFilePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSizeBytes =>
      $composableBuilder(column: $table.fileSizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uploadStatus =>
      $composableBuilder(column: $table.uploadStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PendingFilesTableOrderingComposer extends Composer<_$LocalDb, $PendingFilesTable> {
  $$PendingFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trialLocalId =>
      $composableBuilder(column: $table.trialLocalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trialRemoteId => $composableBuilder(
    column: $table.trialRemoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalName =>
      $composableBuilder(column: $table.originalName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadStatus =>
      $composableBuilder(column: $table.uploadStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PendingFilesTableAnnotationComposer extends Composer<_$LocalDb, $PendingFilesTable> {
  $$PendingFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trialLocalId =>
      $composableBuilder(column: $table.trialLocalId, builder: (column) => column);

  GeneratedColumn<int> get trialRemoteId =>
      $composableBuilder(column: $table.trialRemoteId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get originalName =>
      $composableBuilder(column: $table.originalName, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get localFilePath =>
      $composableBuilder(column: $table.localFilePath, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes =>
      $composableBuilder(column: $table.fileSizeBytes, builder: (column) => column);

  GeneratedColumn<String> get uploadStatus =>
      $composableBuilder(column: $table.uploadStatus, builder: (column) => column);

  GeneratedColumn<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingFilesTableTableManager
    extends
        RootTableManager<
          _$LocalDb,
          $PendingFilesTable,
          PendingFile,
          $$PendingFilesTableFilterComposer,
          $$PendingFilesTableOrderingComposer,
          $$PendingFilesTableAnnotationComposer,
          $$PendingFilesTableCreateCompanionBuilder,
          $$PendingFilesTableUpdateCompanionBuilder,
          (PendingFile, BaseReferences<_$LocalDb, $PendingFilesTable, PendingFile>),
          PendingFile,
          PrefetchHooks Function()
        > {
  $$PendingFilesTableTableManager(_$LocalDb db, $PendingFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PendingFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PendingFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> trialLocalId = const Value.absent(),
                Value<int?> trialRemoteId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> originalName = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<String> localFilePath = const Value.absent(),
                Value<int> fileSizeBytes = const Value.absent(),
                Value<String> uploadStatus = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingFilesCompanion(
                id: id,
                trialLocalId: trialLocalId,
                trialRemoteId: trialRemoteId,
                category: category,
                originalName: originalName,
                mimeType: mimeType,
                localFilePath: localFilePath,
                fileSizeBytes: fileSizeBytes,
                uploadStatus: uploadStatus,
                errorMessage: errorMessage,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> trialLocalId = const Value.absent(),
                Value<int?> trialRemoteId = const Value.absent(),
                required String category,
                required String originalName,
                Value<String?> mimeType = const Value.absent(),
                required String localFilePath,
                required int fileSizeBytes,
                Value<String> uploadStatus = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingFilesCompanion.insert(
                id: id,
                trialLocalId: trialLocalId,
                trialRemoteId: trialRemoteId,
                category: category,
                originalName: originalName,
                mimeType: mimeType,
                localFilePath: localFilePath,
                fileSizeBytes: fileSizeBytes,
                uploadStatus: uploadStatus,
                errorMessage: errorMessage,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDb,
      $PendingFilesTable,
      PendingFile,
      $$PendingFilesTableFilterComposer,
      $$PendingFilesTableOrderingComposer,
      $$PendingFilesTableAnnotationComposer,
      $$PendingFilesTableCreateCompanionBuilder,
      $$PendingFilesTableUpdateCompanionBuilder,
      (PendingFile, BaseReferences<_$LocalDb, $PendingFilesTable, PendingFile>),
      PendingFile,
      PrefetchHooks Function()
    >;

class $LocalDbManager {
  final _$LocalDb _db;
  $LocalDbManager(this._db);
  $$PendingTrialsTableTableManager get pendingTrials =>
      $$PendingTrialsTableTableManager(_db, _db.pendingTrials);
  $$PendingFilesTableTableManager get pendingFiles =>
      $$PendingFilesTableTableManager(_db, _db.pendingFiles);
}
