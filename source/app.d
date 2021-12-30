module app;

import w4 = wasm4;
import std.algorithm : max;

extern (C) int rand();

extern (C) void update() {
  static bool init = false;
  static bool over = false;
  static Bar prev, next;
  static uint score, maxScore;

  if (!init) {
    w4.text("Click to start", 32, 76);
    next = Bar.random();
    next.x = w4.screenSize;
    prev.x = int.max;
    if (*w4.mouseButtons & w4.mouseLeft) init = true;
    return;
  }

  if (!player.ok(next)) {
    over = true;
    maxScore = max(maxScore, score);
  }

  if (over) {
    if (clicked) {
      over = false;
      init = false;
      player = Player.init;
      score = 0;
    }
  } else {
    enum frameRate = 1;
    static uint frameCount;
    ++frameCount;
    if (frameCount % frameRate == 0) {
      ++player.x;
      if (player.x > next.x + next.width) {
        prev = next;
        next = Bar.random();
        ++score;
      }
    }
  }

  next.draw();
  prev.draw();
  player.update();
  player.draw();
  *w4.drawColors = 4;
  w4.text("Score:", 0, 0);
  w4.text(itos(score).ptr, 8 * 6, 0);
  w4.text("Max:", 0, 8);
  w4.text(itos(maxScore).ptr, 8 * 6, 8);
  if (over) w4.text("GAME OVER", 32, 76);
}

bool clicked() {
  static ubyte prevState;
  const mouse = *w4.mouseButtons;
  const justPressed = mouse & (mouse ^ prevState);
  prevState = mouse;
  return (justPressed & w4.mouseLeft) != 0;
}

struct Player {
  int x;
  float y = 76;
  float speed = 0.0;
  enum width = 8;
  enum center = 76;

  void draw() const {
    immutable ubyte[] smiley = [
        0b11000011,
        0b10000001,
        0b00100100,
        0b00100100,
        0b00000000,
        0b00100100,
        0b10011001,
        0b11000011];
    *w4.drawColors = 3;
    w4.blit(smiley.ptr, center, cast(int) y, width, width, w4.blit1Bpp);
  }

  void update() {
    speed += clicked() ? -2.0 : 0.04;
    y += speed;
    if (y >= w4.screenSize - width) {
      y = w4.screenSize - width;
      speed = 0;
    }
    if (y <= 0) {
      y = 0;
      speed = 0;
    }
  }

  bool ok(Bar bar) const {
    if (bar.x <= x + width && x <= bar.x + bar.width) {
      return bar.y <= y && y + width <= bar.y + bar.space;
    }
    return y <= w4.screenSize - width;
  }
}

static Player player;

struct Bar {
  int x = int.max;
  int y;
  static const width = 32;
  static const space = 40;

  static Bar random() {
    return Bar(
        rand() % w4.screenSize / 4 + w4.screenSize / 2 + player.x,
        rand() % (w4.screenSize / 3));
  }

  void draw() {
    *w4.drawColors = 2;
    w4.rect(x - player.x + player.center, 0, width, y);
    auto lower = y + space;
    w4.rect(x - player.x + player.center, lower, width, w4.screenSize - lower);
  }
}

const(char)[] itos(uint i) {
  if (i == 0) return "0";

  enum N = 100;
  static char[N] s = [ N - 1: 0 ];
  foreach_reverse (index; 0 .. N - 1) {
    s[index] = '0' + i % 10;
    i /= 10;
    if (i == 0) return s[index .. $ - 1];
  }
  assert(false, "input is too large for char[N].");
}

unittest {
  assert(itos(0) == "0");
  assert(itos(1) == "1");
  assert(itos(123) == "123");
}
