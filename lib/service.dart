library postgresql_service;

import 'dart:async';

import 'package:redstone/server.dart' as app;
import 'package:redstone_mapper_pg/manager.dart';
import 'package:postgresql/postgresql.dart' as pg;

/**
 * Handles PostgreSQL operations for type T.
 * 
 * Usage:
 * 
 *      PostgreSqlService dbService = new PostgreSqlService<User>();
 * 
 *      @app.Route("/services/user/list")
 *      @Encode()
 *      Future<List<User>> listUsers() => 
 *          dbService.query("select * from users");
 * 
 *      @app.Route("/services/user/add")
 *      Future addUser(@Decode() User user) => 
 *          dbService.execute("insert into users (name, password) "
 *                            "values (@name, @password)", user);
 * 
 * Also, it's possible to inherit from this class:
 * 
 *      @app.Group("/services/user")
 *      Class UserServices extends MongoDbServices<User> {
 * 
 *        UserServices() : super("users");
 * 
 *        @app.Route("/list")
 *        @Encode()
 *        Future<List<User>> list() => 
 *            dbService.query("select * from users");
 *        
 *        @app.Route("/add")
 *        Future add(@Decode() User user) =>
 *            dbService.execute("insert into users (name, password) "
 *                              "values (@name, @password)", user);
 * 
 *      }
 * 
 * By default, the service will use the database connection
 * associated with the current http request. If you are not using
 * Redstone.dart, be sure to use the [PostgreSqlService.fromConnection] 
 * constructor to create a new service.
 * 
 */
class PostgreSqlService<T> {
  
  PostgreSql _postgreSql = null;
  
  ///The PostgreSQL connection wrapper
  PostgreSql get postgreSql => 
      _postgreSql != null ? _postgreSql : app.request.attributes["dbConn"];
  
  ///The PostgreSQL connection
  pg.Connection get innerConn => postgreSql.innerConn;
  
  /**
   * Creates a new PostgreSQL service.
   * 
   * This service will use the database connection
   * associated with the current http request.
   */ 
  PostgreSqlService();
  
  /**
   * Creates a new PostgreSQL service, using the provided
   * PostgreSQL connection.
   */
  PostgreSqlService.fromConnection(this._postgreSql);
  
  /**
   * Wrapper for pg.Connection.query().
   * 
   * [values] can be a List, a Map or an encodable object.
   */
  Future<List<T>> query(String sql, [values]) {
    return postgreSql.query(sql, T, values);
  }
  
  /**
   * Wrapper for pg.Connection.execute().
   * 
   * [values] can be a List, a Map or an encodable object. 
   */
  Future<int> execute(String sql, [values]) {
    return postgreSql.execute(sql, values);
  }
  
}