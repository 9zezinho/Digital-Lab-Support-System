import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:dis/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// This widget represents the page for analysing and displaying feedback
/// data for a specific session. It fetches feedback data, calculates ratings,
/// and provides the ability to send comments to external Flask server for
/// analysis. Additionally, it calculates and displays the average waiting
/// times for different types of requests(Assistance and Sign-Off) within the
/// session

class SessionFinding extends StatefulWidget {
  final String sessionId;
  final String sessionName;

  const SessionFinding({super.key,
    required this.sessionId, required this.sessionName,
    });

  @override
  State<SessionFinding> createState() => _SessionFindingState();
}

class _SessionFindingState extends State<SessionFinding> {
  final FirestoreService firestoreService = FirestoreService();

  //Sending data to Flask Server
  Future<Map<String, dynamic>> getAnalysisResults(List<String> comments
      )
    async {
    //Determine which URi to use based on platform
    String serverUrl;

    if(kIsWeb) {
      //Web Page
      serverUrl = 'http://localhost:8000/process_comments';
    } else {
      //Android Emulator
      serverUrl = 'http://10.0.2.2:8000/process_comments';
    }

    final response = await http.post(
       Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'comments': comments})
    );

    print("Response body: ${response.body}");
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load clustering');
    }
  }

  // Calculate waiting times
  Stream<Map<String, double>> calculateAverageWaitTimes(String sessionId) {
    return firestoreService.getTimeStamp(widget.sessionId)
        .map((requestList) {

      List<double> assistanceDurations = [];
      List<double> signOffDurations = [];

      for (var data in requestList) {
       var created = data['timeStampCreated'];
       var completed = data['timeStampCompleted'];
       var type = data['requestType'];

        if(created != null && completed != null) {
          DateTime createdTime = (created as Timestamp).toDate();
          DateTime completedTime = (completed as Timestamp).toDate();

          Duration diff = completedTime.difference(createdTime);
          double minutes = diff.inSeconds/ 60.0;

          if(type == "assistance") {
            assistanceDurations.add(minutes);
          } else {
            signOffDurations.add(minutes);
          }
        }
      }

      double avgAssistance = assistanceDurations.isNotEmpty
          ? assistanceDurations.reduce((a,b) => a + b) / assistanceDurations.length
          : 0;

      double avgSignOff = signOffDurations.isNotEmpty
          ? signOffDurations.reduce((a,b) => a + b) / signOffDurations.length
          : 0;
      print("Avg Assistance: $avgAssistance minutes");
      print("Avg Sign: $avgSignOff minutes");

      return {
        "assistance": avgAssistance,
        "sign-off": avgSignOff
      };
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sessionName),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>> (
        stream: firestoreService.getFeedbackSummary(widget.sessionId),
        builder: (context, snapshot) {
          if(!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final feedbacks = snapshot.data!;
          if(feedbacks.isEmpty) {
            return const Center(
              child: Text("No feedback available"),
            );
          }

          //Calculation
          double assistanceRatingTotal = 0;
          int assistanceCount = 0;

          double waitingRatingTotal = 0;
          int waitingCount = 0;

          Map<String, int> difficultyCounts = {
            "Easy": 0,
            "Medium": 0,
            "Hard": 0,
          };

          List<String> commentsList = [];

          //Loop through each feedback of that session
          for (var fb in feedbacks){
            if (fb.containsKey('assistanceRating')) {
              assistanceRatingTotal +=
                  (fb['assistanceRating'] ?? 0).toDouble();
              assistanceCount++;
            }

            if(fb.containsKey('waitingTimeRating')) {
              waitingRatingTotal += (fb['waitingTimeRating'] ?? 0).toDouble();
              waitingCount ++;
            }

            String difficulty = fb['labDifficulty'] ?? 'Unknown';
            if (difficultyCounts.containsKey(difficulty)){
              difficultyCounts[difficulty] = difficultyCounts[difficulty]! + 1;
            }

            if(fb.containsKey('comment')) {
              String comment = fb['comment'].toString().trim();
              if (comment.isNotEmpty){
                commentsList.add(comment);
                print("List of comment: $comment");
              }
            }
          }

          double avgAssistanceRating = assistanceCount > 0
              ? assistanceRatingTotal/ feedbacks.length : 0;
          double avgWaitingRating = waitingCount > 0
              ? waitingRatingTotal / feedbacks.length : 0;

          return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Rating Summary",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text("Assistance Rating: $assistanceCount responses"),
                    Text("Waiting Time Rating: $waitingCount responses"),
                    const SizedBox(height: 25),

                    Padding(
                      padding: const EdgeInsets.only(left: 25.0),
                      child: buildRatingsBarChart(avgAssistanceRating,
                          avgWaitingRating),
                    ),

                    const SizedBox(height: 10,),
                    const Text(
                      "Average Waiting Times",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                      ),
                    ),

                    //Showcase the calculation of avg waiting times
                    StreamBuilder<Map<String, double>> (
                      stream: calculateAverageWaitTimes(widget.sessionId),
                      builder: (context, snapshot) {
                        if(!snapshot.hasData) {
                          return Text("NO data");
                        }
                        double assistanceTime = snapshot.data!["assistance"]!;
                        double signOffTime = snapshot.data!["sign-off"]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Assistance: ${assistanceTime
                                .toStringAsFixed(2)} min"),
                            Text("Sign-Off: ${signOffTime
                                .toStringAsFixed(2)} min")
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      "Lab Difficulty Distribution",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 8),
                    buildDifficultyPieChart(difficultyCounts),

                    const SizedBox(height: 16),
                    const Text(
                      "Comments Analysis",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 10,),

                    //Fetch and display the clustering results
                    FutureBuilder<Map<String, dynamic>>(
                        future: getAnalysisResults(commentsList),
                        builder: (context, futureSnapshot) {
                          if(!futureSnapshot.hasData) {
                            return const Center(
                              child: Text("Error")
                            );
                          }

                          final data = futureSnapshot.data!;
                          final wordCloudBase64 = data['word_cloud'];
                          final scatterPlotBase64 = data['sentiment_scatter_plot'];

                          //Convert the base64 image to display
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Word Cloud"),
                              Image.memory(base64Decode(wordCloudBase64),
                                  width: double.infinity,
                                  height: 300,
                                  fit: BoxFit.contain),
                              const SizedBox(height: 16),
                              const Text("Sentiment Scatter Plot: "),
                              Image.memory(base64Decode(scatterPlotBase64),
                                  width: double.infinity,
                                  height: 300,
                                  fit: BoxFit.contain),
                            ],
                          );
                        })
                  ],
                ),
              )
          );
        },
      ),
    );
  }

  // BAR chart for assistance Rating and waitingTimeRating
  Widget buildRatingsBarChart(double avgAssistance, double avgWaiting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
                minY: 0,
                maxY: 5,
                //Rating are out of 5
                alignment: BarChartAlignment.center,
                barGroups: [
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                          toY: double.parse(avgAssistance.toStringAsFixed(1)),
                          color: Colors.blue,
                          width: 30,
                          borderRadius: BorderRadius.circular(4)),
                    ],
                    showingTooltipIndicators: [0],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                          toY: double.parse(avgWaiting.toStringAsFixed(1)),
                          color: Colors.purpleAccent,
                          width: 30,
                          borderRadius: BorderRadius.circular(4))
                    ],
                    showingTooltipIndicators: [0],
                  )
                ],
                titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                        sideTitles:
                        SideTitles(showTitles: true,
                          reservedSize: 32,

                        )
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 32,
                          getTitlesWidget: (value, _) {
                            return Text(value.toInt().toString());
                          }),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    )),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    drawHorizontalLine: true,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                          color: Colors.grey,
                          strokeWidth: 1
                      );
                    }
                )
            ),
          ),
        ),

        const SizedBox(height: 8,),
        Row(
          children: [
            _buildLegendItem(Colors.blue, "Assistance"),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.purpleAccent, "Waiting")
          ],
        )
      ],
    );
  }

  //Legend Item
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2)
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black),
        )
      ],
    );
  }

  //PIE Chart for lab difficulty
  Widget buildDifficultyPieChart(Map<String, int> difficultyCounts) {
    final total = difficultyCounts.values.fold(0, (sum, val) => sum + val);

    final colors = {
      "Easy": Colors.green,
      "Medium": Colors.orange,
      "Hard": Colors.red,
    };

    return SizedBox(
        height: 200,
        child: PieChart(
            PieChartData(
              sections: difficultyCounts.entries.map((entry) {
                final percent = entry.value / total * 100;
                return PieChartSectionData(
                  color: colors[entry.key],
                  value: entry.value.toDouble(),
                  title: '${entry.key}\n${percent.toStringAsFixed(1)}%',
                  radius: 60,
                  titleStyle: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.bold),
                );
              }).toList(),

              borderData: FlBorderData(show: true),

            )
        )
    );

  }
}
