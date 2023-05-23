import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(ColorTapGame());
}

class ColorTapGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Tap',
      theme: ThemeData(
        primarySwatch: Colors.purple[600],
      ),
      home: ColorTapScreen(),
    );
  }
}

class ColorTapScreen extends StatefulWidget {
  @override
  _ColorTapScreenState createState() => _ColorTapScreenState();
}

class _ColorTapScreenState extends State<ColorTapScreen>
    with SingleTickerProviderStateMixin {
  int difficultyLevel = 1;
  int lives = 3;
  bool isJumping = true;
  int score = 0;

  Color mainColor = Colors.red;
  List<Color> obstacleColors = [
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.purple,
  ];
  List<Color> obstacles = [];
  int centerObstacle = 0;

  late AnimationController _colorAnimationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    generateObstacles();

    _colorAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: mainColor,
    ).animate(_colorAnimationController);
  }

  @override
  void dispose() {
    _colorAnimationController.dispose();
    super.dispose();
  }

  void handleTap() {
    if (lives <= 0) {
      restart();
      return;
    }

    generateObstacles();
    setState(() {
      isJumping = true;
      setState(() {
        score++;
      });
      _colorAnimationController.forward(from: 0.0);
    });
  }

  void handleCollision() {
    setState(() {
      lives--;
      if (lives <= 0) {
        isJumping = false;
      }
    });
  }

  void generateObstacles() {
    if (obstacles.length > 0) {
      final bool giveNewPass =
          !obstacles.any((Color obstacle) => obstacle == mainColor);
      obstacles.removeAt(0);

      addObstacle(giveNewPass: giveNewPass);
    } else {
      final numObstacles = [3, 5][difficultyLevel - 1];
      for (int i = 0; i < numObstacles; i++) {
        addObstacle();
      }
    }

    centerObstacle = obstacles.length ~/ 2;

    setState(() {});
  }

  void addObstacle({
    bool giveNewPass = false,
  }) {
    final random = Random();

    final randomColorIndex = random.nextInt(obstacleColors.length);
    obstacles.add(
        giveNewPass == true ? mainColor : obstacleColors[randomColorIndex]);
  }

  void restart() {
    setState(() {
      obstacles.clear();
      generateObstacles();
      score = 0;
      lives = 3;
      isJumping = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Color Tap'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: handleTap,
        child: Stack(
          children: [
            Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LivesBar(lives: lives),
                  Text(
                    'Tap to Jump!',
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(height: 16),
                  SizedBox(height: 16),
                  ObstaclesWidget(
                    dotPosition: Offset(100, 100),
                    dotSize: Size(50, 50),
                    obstacles: obstacles,
                    colorAnimation: _colorAnimation,
                    isColliding: false, //TODO implement
                  ),
                  DotWidget(
                    isJumping: isJumping,
                    currentObstacleColor: obstacles[centerObstacle],
                    mainColor: mainColor,
                    onCollision: handleCollision,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Score: $score',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
            if (lives <= 0) GameEndScreen(score: score, onRestart: () {}),
          ],
        ),
      ),
    );
  }
}

class DotWidget extends StatefulWidget {
  final bool isJumping;
  final Function onCollision;
  final Color currentObstacleColor;
  final Color mainColor;

  const DotWidget({
    required this.isJumping,
    required this.onCollision,
    required this.currentObstacleColor,
    required this.mainColor,
  });

  @override
  _DotWidgetState createState() => _DotWidgetState();
}

class _DotWidgetState extends State<DotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _jumpController;
  late Animation<double> _jumpAnimation;

  @override
  void initState() {
    super.initState();

    _jumpController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _jumpAnimation = Tween<double>(begin: -200, end: 0).animate(
      CurvedAnimation(parent: _jumpController, curve: Curves.easeInOut),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _jumpController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _jumpController.forward();
        }
      })
      ..addListener(() {
        final obstacleRect = Rect.fromCenter(
          center: Offset(0, -110),
          width: 45,
          height: 45,
        );
        final obstacleRect2 = Rect.fromCenter(
          center: Offset(0, -90),
          width: 45,
          height: 45,
        );

        final obstacleRect3 = Rect.fromCenter(
          center: Offset(0, -100),
          width: 50,
          height: 50,
        );

        final rect = Rect.fromCenter(
          center: Offset(0, _jumpAnimation.value),
          width: 50,
          height: 50,
        );

        if (rect.overlaps(obstacleRect3)) {
          return;
        }

        if (widget.currentObstacleColor != widget.mainColor) {
          if (rect.overlaps(obstacleRect) &&
              _jumpAnimation.status == AnimationStatus.forward) {
            widget.onCollision();
            _jumpController.reverse();
          } else if (rect.overlaps(obstacleRect2) &&
              _jumpAnimation.status == AnimationStatus.reverse) {
            widget.onCollision();
            _jumpController.forward();
          }
        }
      });

    _jumpController.forward();
  }

  @override
  void dispose() {
    _jumpController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isJumping && !oldWidget.isJumping) {
      _jumpController.forward(from: 0);
    } else if (!widget.isJumping) {
      _jumpController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _jumpController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _jumpAnimation.value),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: widget.mainColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class ObstaclesWidget extends StatelessWidget {
  final List<Color> obstacles;
  final Offset dotPosition;
  final Size dotSize;
  final Animation<Color?> colorAnimation;
  final bool isColliding;

  const ObstaclesWidget({
    required this.obstacles,
    required this.dotPosition,
    required this.dotSize,
    required this.colorAnimation,
    required this.isColliding,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.rotationX(4),
      alignment: Alignment.center,
      child: Container(
        width: double.infinity,
        height: 150,
        color: Colors.grey,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: obstacles.map((color) {
            return ObstacleWidget(
              color: color,
              dotPosition: dotPosition,
              dotSize: dotSize,
              colorAnimation: colorAnimation,
              isColliding: isColliding,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ObstacleWidget extends StatefulWidget {
  final Color color;
  final Offset dotPosition;
  final Size dotSize;
  final Animation<Color?> colorAnimation;
  final bool isColliding;

  const ObstacleWidget({
    required this.color,
    required this.dotPosition,
    required this.dotSize,
    required this.colorAnimation,
    required this.isColliding,
  });

  @override
  _ObstacleWidgetState createState() => _ObstacleWidgetState();
}

class _ObstacleWidgetState extends State<ObstacleWidget>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.colorAnimation,
      builder: (context, child) {
        return IgnorePointer(
          child: Opacity(
            opacity: widget.isColliding ? 0.3 : 1.0,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class LivesBar extends StatelessWidget {
  final int lives;

  const LivesBar({required this.lives});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => Icon(
            index < lives ? Icons.favorite : Icons.favorite_border,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}

class GameEndScreen extends StatelessWidget {
  final int score;
  final VoidCallback onRestart;

  const GameEndScreen({required this.score, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Game Over',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Score: $score',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRestart,
                child: Text('Restart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
