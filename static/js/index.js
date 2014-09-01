var x$;
x$ = angular.module('main', []);
x$.controller('main', ['$scope'].concat(function($scope){
  return console.log('loaded');
}));
