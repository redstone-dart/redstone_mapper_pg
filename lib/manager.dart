library postgresql_manager;

import 'dart:async';

import 'package:redstone_mapper/database.dart';
import 'package:redstone_mapper/mapper.dart' as mapper;
import 'package:postgresql/postgresql.dart' as pg;
import 'package:postgresql/postgresql_pool.dart';

///Manage connections with a PostgreSQL instance
class PostgreSqlManager implements DatabaseManager<PostgreSql> {
  
  Pool _pool;
  Future _init;
  
  /**
   * Creates a new PostgreSqlManager.
   * 
   * [uri] a PostgreSQL uri, and [min] and [max] are the minimun
   * and maximum number of connections that will be created, 
   * respectively. 
   */ 
  PostgreSqlManager(String uri, {int min: 1, int max: 3}) {
    _pool = new Pool(uri, minConnections: min, maxConnections: max);
    _init = _pool.start();
  }
  
  @override
  void closeConnection(PostgreSql connection, {error}) {
    connection.innerConn.close();
  }

  @override
  Future<PostgreSql> getConnection() {
    return _init.then((_) => _pool.connect())
                .then((conn) => new PostgreSql(conn));
  }
}

/**
 * Wrapper for the PostgreSQL driver.
 * 
 * This class provides helper functions for
 * enconding query parameters and decoding query
 * results using redstone_mapper.
 * 
 */ 
class PostgreSql {
  
  ///The original PostgreSQL connection object.
  final pg.Connection innerConn;
  
  PostgreSql(this.innerConn);
  
  ///Encode [data] to a Map or List.
  dynamic encode(dynamic data) =>
      _codec.encode(data);
    
  ///Decode [row] to one or more objects of type [type].
  dynamic decode(pg.Row row, Type type) {
    var data = {};
    row.forEach((String columnName, dynamic value) {
      data[columnName] = value;
    });
    return _codec.decode(data, type);
  }
  
  /**
   * Wrapper for pg.Connection.query().
   * 
   * [values] can be a List, a Map or an encodable object. 
   * The query result will be decoded to List<[type]>.
   * 
   */ 
  Future<List> query(String sql, Type type, [values]) {
    if (values != null && values is! Map && values is! List) {
      values = _codec.encode(values);
    }
    return innerConn.query(sql, values).toList().then((rows)
        => rows.map((row) => decode(row, type)).toList());
  }

  /**
   * Wrapper for pg.Connection.execute().
   * 
   * [values] can be a List, a Map or an encodable object. 
   */ 
  Future<int> execute(String sql, [values]) {
    if (values != null && values is! Map && values is! Map ) {
      values = _codec.encode(values);
    }
    return innerConn.execute(sql, values);
  }
  
}

mapper.FieldDecoder _fieldDecoder = (Object data, String fieldName, 
                                     mapper.Field fieldInfo, List metadata) {
  String name = fieldInfo.model;
  if (name == null) {
    name = fieldName;
  }
  return (data as Map)[name];
};

mapper.FieldEncoder _fieldEncoder = (Map data, String fieldName, 
                                     mapper.Field fieldInfo, 
                                     List metadata, Object value) {
  String name = fieldInfo.model;
  if (name == null) {
    name = fieldName;
  }
  data[name] = value;
};

mapper.GenericTypeCodec _codec = new mapper.GenericTypeCodec(
    fieldDecoder: _fieldDecoder,
    fieldEncoder: _fieldEncoder);