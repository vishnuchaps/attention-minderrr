import 'package:attention_minder/service/notification_service.dart';
import 'package:attention_minder/service/session_data.dart';
import 'package:flutter/material.dart';

class SessionSummaryScreen extends StatefulWidget {
  final SessionData sessionData;

  const SessionSummaryScreen({
    Key? key,
    required this.sessionData,
  }) : super(key: key);

  @override
  _SessionSummaryScreenState createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.sessionData.attentionScore / 100.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _initializeAndPlay();
  }

  Future<void> _initializeAndPlay() async {
    await _notificationService.initialize();
    await _notificationService.playSessionComplete();

    _fadeController.forward();
    await Future.delayed(Duration(milliseconds: 500));
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    _notificationService.dispose();
    super.dispose();
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }

  String _getPerformanceMessage(int score) {
    if (score >= 90) return "Outstanding Focus! 🌟";
    if (score >= 80) return "Excellent Attention! 👏";
    if (score >= 70) return "Great Progress! 💪";
    if (score >= 60) return "Good Effort! 👍";
    if (score >= 50) return "Keep Improving! 📈";
    return "Practice Makes Perfect! 🎯";
  }

  String _getRecommendation(int score) {
    if (score >= 80) {
      return "Maintain this excellent focus level in future sessions.";
    } else if (score >= 60) {
      return "Try to minimize distractions for even better results.";
    } else if (score >= 40) {
      return "Consider practicing in a quieter environment.";
    } else {
      return "Focus on looking at the screen throughout the session.";
    }
  }

  Widget _buildScoreCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getScoreColor(widget.sessionData.attentionScore).withOpacity(0.1),
              _getScoreColor(widget.sessionData.attentionScore).withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Text(
              _getPerformanceMessage(widget.sessionData.attentionScore),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(widget.sessionData.attentionScore),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: _progressAnimation.value,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getScoreColor(widget.sessionData.attentionScore),
                        ),
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Text(
                          '${(_progressAnimation.value * 100).round()}%',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(widget.sessionData.attentionScore),
                          ),
                        );
                      },
                    ),
                    Text(
                      'Attention Score',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            _buildStatRow(
              icon: Icons.timer,
              label: 'Duration',
              value: _formatDuration(widget.sessionData.totalDuration),
              color: Colors.blue,
            ),
            _buildStatRow(
              icon: Icons.visibility,
              label: 'Focus Time',
              value: _formatDuration(Duration(
                seconds: (widget.sessionData.totalDuration.inSeconds *
                    widget.sessionData.focusPercentage / 100).round(),
              )),
              color: Colors.green,
            ),
            _buildStatRow(
              icon: Icons.warning,
              label: 'Distractions',
              value: '${widget.sessionData.distractionCount}',
              color: Colors.orange,
            ),
            _buildStatRow(
              icon: Icons.trending_up,
              label: 'Focus Rate',
              value: '${widget.sessionData.focusPercentage.toStringAsFixed(1)}%',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistractionsTimeline() {
    if (widget.sessionData.distractions.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distraction Timeline',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: ListView.builder(
                itemCount: widget.sessionData.distractions.length,
                itemBuilder: (context, index) {
                  final distraction = widget.sessionData.distractions[index];
                  return _buildDistractionItem(distraction, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistractionItem(DistractionEvent distraction, int index) {
    final timeSinceStart = distraction.timestamp.difference(widget.sessionData.startTime);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility_off,
            color: _getAlertColor(distraction.alertLevel),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distraction #${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'At ${_formatDuration(timeSinceStart)} - Duration: ${_formatDuration(distraction.duration)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getAlertColor(distraction.alertLevel),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              distraction.alertLevel.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(String alertLevel) {
    switch (alertLevel.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'moderate':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecommendationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.blue[25]!],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue[700], size: 24),
                SizedBox(width: 8),
                Text(
                  'Recommendation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              _getRecommendation(widget.sessionData.attentionScore),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Session Complete'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildScoreCard(),
              SizedBox(height: 16),
              _buildStatisticsCard(),
              SizedBox(height: 16),
              _buildRecommendationCard(),
              SizedBox(height: 16),
              _buildDistractionsTimeline(),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.home),
                      label: Text('Back to Home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigate to new session
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('New Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}