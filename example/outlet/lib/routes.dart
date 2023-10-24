import 'package:routefly/routefly.dart';

import 'app/app_page.dart' as a0;
import 'app/dashboard/dashboard_layout.dart' as a1;
import 'app/dashboard/option1_page.dart' as a2;
import 'app/dashboard/option2_page.dart' as a3;
import 'app/dashboard/option3_page.dart' as a4;

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
    key: '/dashboard',
    uri: Uri.parse('/dashboard'),
    routeBuilder: (ctx, settings) => Routefly.defaultRouteBuilder(
      ctx,
      settings,
      const a1.DashboardLayout(),
    ),
  ),
  RouteEntity(
    key: '/dashboard/option1',
    parent: '/dashboard',
    uri: Uri.parse('/dashboard/option1'),
    routeBuilder: a2.routeBuilder,
  ),
  RouteEntity(
    key: '/dashboard/option2',
    parent: '/dashboard',
    uri: Uri.parse('/dashboard/option2'),
    routeBuilder: a3.routeBuilder,
  ),
  RouteEntity(
    key: '/dashboard/option3',
    parent: '/dashboard',
    uri: Uri.parse('/dashboard/option3'),
    routeBuilder: a4.routeBuilder,
  ),
];

const routePaths = (
  path: '/',
  dashboard: (
    path: '/dashboard',
    option1: '/dashboard/option1',
    option2: '/dashboard/option2',
    option3: '/dashboard/option3',
  ),
);
