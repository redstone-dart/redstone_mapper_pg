library redstone_postgresql_service;

import 'package:redstone/redstone.dart';
import 'package:redstone_mapper/mapper.dart';
import 'package:redstone_mapper/plugin.dart';
import 'package:redstone_mapper_pg/service.dart';

class User {
  
  @Field()
  int id;
  
  @Field()
  String username;
  
  @Field()
  String password;
  
  operator == (other) {
    return other is User &&
           other.id == id &&
           other.username == username &&
           other.password == password;
  }
  
  toString() => "id: $id username: $username password: $password";
}

PostgreSqlService _service = new PostgreSqlService<User>();

@Route("/find")
@Encode()
find() => _service.query("select * from user");

@Route("/save", methods: const [POST])
save(@Decode() User user) =>
    _service.execute("insert into user set "
                     "username = @username "
                     "and password = @password", user)
    .then((_) => {"success": true});

