import 'package:routefly/routefly.dart';

import 'app/app_page.dart' as a0;
import 'app/guarded/guarded_page.dart' as a1;
import 'app/users/[id]_page.dart' as a3;
import 'app/users/users_page.dart' as a2;

List<RouteEntity> get routes => [
  RouteEntity(
    key: '/',
    uri: Uri.parse('/'),
    routeBuilder: (ctx, settings) => Routefly.defaultRouteBuilder(
      ctx,
      settings,
      const a0.AppPage(),
    ),
  ),
  RouteEntity(
    key: '/guarded',
    uri: Uri.parse('/guarded'),
    routeBuilder: (ctx, settings) => Routefly.defaultRouteBuilder(
      ctx,
      settings,
      const a1.GuardedPage(),
    ),
  ),
  RouteEntity(
    key: '/users',
    uri: Uri.parse('/users'),
    routeBuilder: (ctx, settings) => Routefly.defaultRouteBuilder(
      ctx,
      settings,
      const a2.UsersPage(),
    ),
  ),
  RouteEntity(
    key: '/users/[id]',
    uri: Uri.parse('/users/[id]'),
    routeBuilder: a3.routeBuilder,
  ),
];

const routePaths = (
  path: '/',
  guarded: '/guarded',
  users: (
    path: '/users',
    $id: '/users/[id]',
  ),
);
