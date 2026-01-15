class Player {
  int x; // position in grid, x from 0 to 4 (5 columns)
  int y; // y from 0 to 7 (8 rows)
  int health;
  int steps;

  Player({this.x = 2, this.y = 0, this.health = 10, this.steps = 20});
}
