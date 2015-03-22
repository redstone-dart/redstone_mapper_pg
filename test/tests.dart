library mapper_postgresql_tests;

import 'dart:async';
import 'dart:convert' as conv;

import 'package:unittest/unittest.dart';
import 'package:mock/mock.dart';

import 'package:redstone/redstone.dart';

import 'package:redstone_mapper/mapper_factory.dart';
import 'package:redstone_mapper_pg/manager.dart';
import 'package:redstone_mapper/database.dart';
import 'package:redstone_mapper/plugin.dart';
import 'package:postgresql/postgresql.dart' as pg;

import 'redstone_service.dart';

class MockConn extends Mock implements pg.Connection {

  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
  
}

class MockPostgreSqlManager implements DatabaseManager<PostgreSql> {
  
  PostgreSql postgreSql;
  
  MockPostgreSqlManager(this.postgreSql);
  
  @override
  void closeConnection(PostgreSql connection, {error}) {
  }

  @override
  Future<PostgreSql> getConnection() {
    return new Future.value(postgreSql);
  }
}

class MockRow implements pg.Row {
  
  Map values;
  
  MockRow(this.values);

  @override
  void forEach(void f(String columnName, columnValue)) {
    values.forEach(f);
  }
  
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

main() {
  
  bootstrapMapper();
  
  var userObj = new User()
                  ..id = 1
                  ..username = "user"
                  ..password = "1234";
  
  var userMap = {
    "id": 1,
    "username": "user",
    "password": "1234"
  };
  
  PostgreSql postgreSql;
  MockConn mockConn;
  
  setUp(() {
    mockConn = new MockConn();
    postgreSql = new PostgreSql(mockConn);
  });
  
  test("Decode", () {
    mockConn.when(callsTo("query")).alwaysReturn(
        new Stream.fromIterable(
            [userMap, userMap, userMap].map((u) => new MockRow(u))));
    return postgreSql.query("query", User).then((users) {
      expect(users, equals([userObj, userObj, userObj]));
    });
  });
  
  test("Encode", () {
    var encodedUser;
    mockConn.when(callsTo("execute")).alwaysCall((String sql, [values]) {
      encodedUser = values;
      return new Future.value(1);
    });
    return postgreSql.execute("query", userObj).then((_) {
      mockConn.getLogs(callsTo("execute")).verify(happenedOnce);
      expect(encodedUser, equals(userMap));
    });
  });
  
  group("PostgreSqlService:", () {
    
    var userJson = {
      "id": 1,
      "username": "user",
      "password": "1234"
    };
    
    setUp(() async {
      var dbManager = new MockPostgreSqlManager(postgreSql);
      addPlugin(getMapperPlugin(dbManager));
      await redstoneSetUp([#redstone_postgresql_service]);
    });
    
    tearDown(redstoneTearDown);
    
    test("find", () {
      mockConn.when(callsTo("query")).alwaysReturn(
          new Stream.fromIterable(
              [userMap, userMap, userMap].map((u) => new MockRow(u))));

      var req = new MockRequest("/find");
      return dispatch(req).then((resp) {
        expect(resp.mockContent, equals(conv.JSON.encode([userJson, userJson, userJson])));
      });
    });
    
    test("save", () {
      var encodedUser;
      mockConn.when(callsTo("execute")).alwaysCall((String sql, [values]) {
        encodedUser = values;
        return new Future.value(1);
      });
      
      var req = new MockRequest("/save", method: POST, 
          bodyType: JSON, body: userJson);
      return dispatch(req).then((resp) {
        mockConn.getLogs(callsTo("execute")).verify(happenedOnce);
        expect(encodedUser, equals(userMap));
        expect(resp.mockContent, conv.JSON.encode({"success": true}));
      });
    });
  });
 
}