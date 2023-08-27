import 'dart:convert';
import 'dart:io';

import 'package:a_dance/main.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PersonalReport extends StatefulWidget {
  final List<double> data;
  final String title;
  final int score;
  final List<String> frame_rank;
  final List<List<Offset>> allFramesKeypoints;
  final String videoPath;

  PersonalReport(
      {required this.data,
      required this.title,
      required this.score,
      required this.allFramesKeypoints,
      required this.videoPath,
      required this.frame_rank});

  @override
  _PersonalReport createState() => _PersonalReport();
}

class _PersonalReport extends State<PersonalReport> {
  List<int> findBadStartingIndices(List<String> rankList) {
    List<int> result = [];
    for (int i = 0; i < rankList.length; i++) {
      if (rankList[i] == "Bad" && (i == 0 || rankList[i - 1] != "Bad")) {
        result.add(i);
        if (result.length == 3) break;
      }
    }
    return result;
  }

  Future<String> captureImageFromVideo(
      String videoPath, int startTimeInSeconds) async {
    final FlutterFFmpeg _ffmpeg = FlutterFFmpeg();
    final directory = await getTemporaryDirectory();
    final String outputPath =
        '${directory.path}/captured_frame_${DateTime.now().millisecondsSinceEpoch}.png';
    final String command =
        '-i $videoPath -ss 00:00:${startTimeInSeconds} -vframes 1 $outputPath';
    await _ffmpeg.execute(command);
    return outputPath;
  }

  Future<int> getAvgScore() async {
    print('frame_rank = ${widget.frame_rank}');
    print('frame_rank = ${widget.allFramesKeypoints}');

    int avgScore = 0;

    final Uri url = Uri.parse('$URL/api/get_leaderboard');
    final Map<String, dynamic> requestBody = {"title": widget.title, "num": 10};

    final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody));
    print('response getavgscore = ${response.statusCode}');

    double totalScore = 0;

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      print('getavgscore responseData = $responseData');
      List<dynamic> leaderboard = responseData['leaderboard'];
      print('leaderboard list = $leaderboard');
      for (var entry in leaderboard) {
        totalScore += entry['score'];
      }
      avgScore = (totalScore / leaderboard.length).round().toInt();
    }
    print('avgScore = $avgScore');

    return avgScore;
  }

  int get dldl => widget.data.length; // 계산된 getter

  @override
  Widget build(BuildContext context) {
    List<int> badStartIndices = findBadStartingIndices(widget.frame_rank);
    print("Bad start indices: $badStartIndices");

    final double firstBadFrameTime = badStartIndices[0] / 30;
    final double secondBadFrameTime = badStartIndices[1] / 30;
    final double thirdBadFrameTime = badStartIndices[2] / 30;

    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFFE5E4EE), // 회색 배경
        body: FutureBuilder<List>(
            future: Future.wait([
              getAvgScore(),
              captureImageFromVideo(
                  widget.videoPath, firstBadFrameTime.round().toInt()),
              captureImageFromVideo(
                  widget.videoPath, secondBadFrameTime.round().toInt()),
              captureImageFromVideo(
                  widget.videoPath, thirdBadFrameTime.round().toInt())
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.error != null) {
                return Center(child: Text('An error occurred!'));
              } else
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 50), // Size Box 높이

                      // 흰색 컨테이너
                      Container(
                        height: 2200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.2), // 그림자 색상 및 투명도 조절
                              offset: Offset(-1, -4), // (x, y) 그림자의 오프셋 조절
                              blurRadius: 5, // 그림자의 흐림 정도 조절
                            ),
                          ],
                        ),
                        //padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 1,
                                ),
                                IconButton(
                                  icon: Icon(Icons.arrow_back_ios_new_rounded),
                                  onPressed: () {
                                    // Navigator.pushAndRemoveUntil(
                                    //     context,
                                    //     MaterialPageRoute(
                                    //         builder: (BuildContext context) =>
                                    //             Adot_Main()),
                                    //     (route) => false);
                                  },
                                ),
                                SizedBox(
                                  width: 70,
                                ),
                                Text(
                                  "개인 리포트",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(
                                  width: 70,
                                ),
                                IconButton(
                                  icon: Icon(Icons.more_vert_rounded),
                                  onPressed: () {
                                    // showDialog(
                                    //   context: context,
                                    //   builder: (BuildContext context) {
                                    //     return AlertDialog(
                                    //       title: Text('더보기'),
                                    //       content: Text('팝업 창 내용'),
                                    //       actions: [
                                    //         ElevatedButton(
                                    //           onPressed: () {
                                    //             Navigator.pushAndRemoveUntil(
                                    //                 context,
                                    //                 MaterialPageRoute(
                                    //                     builder:
                                    //                         (BuildContext context) =>
                                    //                             Adot_Main()),
                                    //                 (route) => false);
                                    //           },
                                    //           child: Text('닫기'),
                                    //         ),
                                    //       ],
                                    //     );
                                    //   },
                                    // );
                                  },
                                ),
                                SizedBox(width: 1),
                              ],
                            ),
                            SizedBox(height: 50),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '사용자 닉네임',
                                    style: TextStyle(
                                      color: Color(0xFF9EA3B1),
                                      fontSize: 28,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      height: 1.50,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' 님의\n',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 28,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      height: 1.50,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '에이단ㅡ스',
                                    style: TextStyle(
                                      color: Color(0xFF5252FF),
                                      fontSize: 28,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      height: 1.50,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' 분석 리포트',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 28,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      height: 1.50,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            Container(
                              padding: EdgeInsets.all(8.0),
                              width: 320,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '정확도 그래프',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF6F6FFA),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '정확도(%)',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Container(
                                    width: 300,
                                    height: 150,
                                    child: LineChart(
                                      LineChartData(
                                        minY: 0,
                                        maxY: 100,
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: true,
                                          drawHorizontalLine: true,
                                        ),
                                        titlesData: FlTitlesData(show: false),
                                        borderData: FlBorderData(
                                            show: true,
                                            border: Border(
                                              left: BorderSide(
                                                  color: const Color.fromARGB(
                                                      255, 158, 158, 158)),
                                              bottom: BorderSide(
                                                  color: const Color.fromARGB(
                                                      255, 158, 158, 158)),
                                            )),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: List.generate(10, (index) {
                                              return FlSpot(index.toDouble(),
                                                  widget.data[index]);
                                            }),
                                            isCurved: true,
                                            color: Color.fromARGB(
                                                255, 121, 121, 250),
                                            dotData: FlDotData(show: false),
                                            belowBarData:
                                                BarAreaData(show: false),
                                            barWidth: 7,
                                            //preventCurveOverShooting: true,
                                            // isStrokeJoinRound: true,
                                            isStrokeCapRound: true,
                                            shadow: Shadow(
                                              color: Color.fromARGB(
                                                  255, 177, 177, 177),
                                              offset: Offset(0, 2),
                                              blurRadius: 5.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            Container(
                              height: 125,
                              padding:
                                  const EdgeInsets.only(top: 11, bottom: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  //평균 정확도
                                  Container(
                                    width: 300,
                                    height: 125,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 13,
                                      horizontal: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(25),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(
                                              0.1), // 그림자 색상 및 투명도 조절
                                          offset: Offset(
                                              1, 2), // (x, y) 그림자의 오프셋 조절
                                          blurRadius: 5, // 그림자의 흐림 정도 조절
                                        ),
                                      ],
                                    ),
                                    child: Column(children: [
                                      Row(
                                        children: [
                                          SizedBox(width: 5),
                                          Icon(
                                            Icons.insert_chart_rounded,
                                            color: Color(0xFF5252FF),
                                          ),
                                          SizedBox(width: 5), // 아이콘과 텍스트 간격
                                          Text(
                                            '평균 정확도',
                                            style: TextStyle(
                                              color: Color(0xFFA0AEC0),
                                              fontSize: 12,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 8,
                                          ),
                                          SizedBox(
                                            width: 50,
                                            height: 30,
                                            child: Text(
                                              '${widget.score}%',
                                              style: TextStyle(
                                                color: Color(0xFF2D3748),
                                                fontSize: 23,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 40,
                                            height: 15,
                                            child: (widget.score -
                                                        snapshot.data![0]) >
                                                    0
                                                ? Text(
                                                    '+${widget.score - snapshot.data![0]}%',
                                                    style: TextStyle(
                                                      color: Color(0xFF48BB78),
                                                      fontSize: 11,
                                                      fontFamily: 'Inter',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.left,
                                                  )
                                                : Text(
                                                    '${widget.score - snapshot.data![0]}%',
                                                    style: TextStyle(
                                                      color: Color(0xFFE53E3E),
                                                      fontSize: 11,
                                                      fontFamily: 'Inter',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.left,
                                                  ),
                                          )
                                        ],
                                      ),
                                      SizedBox(
                                        height: 20,
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Container(
                                            width: 72,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF5252FF),
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(
                                                    2.5), // 왼쪽 끝을 라운드 처리
                                                bottomLeft:
                                                    Radius.circular(2.5),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 28,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: Color(0xFFA0AEC0),
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(
                                                    2.5), // 오른쪽 끝을 라운드 처리
                                                bottomRight:
                                                    Radius.circular(2.5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ]),
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 30),
                            //정확도 결과 컨테이너
                            Container(
                              height: 1460,
                              decoration: BoxDecoration(
                                color: Color(0xFF5252FF),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(25),
                                  topRight: Radius.circular(25),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.2), // 그림자 색상 및 투명도 조절
                                    offset:
                                        Offset(-1, -4), // (x, y) 그림자의 오프셋 조절
                                    blurRadius: 5, // 그림자의 흐림 정도 조절
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 45,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(
                                        CupertinoIcons.sparkles,
                                        color: Colors.amber,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        "정확도가 낮은 부분을",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 24,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 40),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        "조금만 더 연습해보세요!",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 24,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 40)
                                    ],
                                  ),
                                  SizedBox(height: 30),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 350,
                                        child: ElevatedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white70,
                                            shadowColor: Colors.transparent,
                                            elevation: 10, // 그림자의 깊이 조절
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 10),
                                          ),
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment(0.00, -1.00),
                                                end: Alignment(0, 1),
                                                colors: [
                                                  Color(0xFFCFCFFB),
                                                  Color(0xFFE7E7FF)
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                            ),
                                            child: Container(
                                              constraints: BoxConstraints(
                                                  minWidth: 160, minHeight: 48),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  // SizedBox(
                                                  //   width: 100,
                                                  // ),
                                                  Icon(
                                                      CupertinoIcons
                                                          .hand_point_right_fill,
                                                      color: Colors.amber),
                                                  Text(
                                                    " ${firstBadFrameTime.toStringAsFixed(2)} ~ ${(firstBadFrameTime + 3).toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 24,
                                                        color: Colors.black),
                                                  ),
                                                  // SizedBox(
                                                  //   width: 100,
                                                  // ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20.0),
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Color.fromRGBO(255, 255, 255, 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 50, horizontal: 40),
                                      elevation: 30, // 그림자의 깊이 조절
                                      shadowColor: Colors.grey
                                          .withOpacity(0.7), // 그림자 색상과 투명도 조절
                                    ),
                                    child: Row(
                                      children: [
                                        Image.file(
                                          File(snapshot.data![1]),
                                          width: 100,
                                          height: 190,
                                        ),
                                        SizedBox(width: 30),
                                        SizedBox(
                                          width: 150,
                                          height: 70,
                                          child: Text(
                                            '음악과 박자를 맞추어 보세요!',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 20,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 30,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 350,
                                        child: ElevatedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white70,
                                            shadowColor: Colors.transparent,
                                            elevation: 10, // 그림자의 깊이 조절
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 10),
                                          ),
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment(0.00, -1.00),
                                                end: Alignment(0, 1),
                                                colors: [
                                                  Color(0xFFCFCFFB),
                                                  Color(0xFFE7E7FF)
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                            ),
                                            child: Container(
                                              constraints: BoxConstraints(
                                                  minWidth: 160, minHeight: 48),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  // SizedBox(
                                                  //   width: 100,
                                                  // ),
                                                  Icon(
                                                      CupertinoIcons
                                                          .hand_point_right_fill,
                                                      color: Colors.amber),
                                                  Text(
                                                    " ${secondBadFrameTime.toStringAsFixed(2)} ~ ${(secondBadFrameTime + 3).toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 24,
                                                        color: Colors.black),
                                                  ),
                                                  // SizedBox(
                                                  //   width: 100,
                                                  // ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20.0),
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Color.fromRGBO(255, 255, 255, 20),
                                      shadowColor: Colors.transparent,
                                      elevation: 10, // 그림자의 깊이 조절
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 50, horizontal: 40),
                                    ),
                                    child: Row(
                                      children: [
                                        Image.file(
                                          File(snapshot.data![2]),
                                          width: 100,
                                          height: 190,
                                        ),
                                        SizedBox(width: 30),
                                        SizedBox(
                                          width: 150,
                                          // height: 70,
                                          child: Text(
                                            '왼팔의 움직임에 조금 더 주의를 기울여 보세요!',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 20,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 30,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white70,
                                          shadowColor: Colors.transparent,
                                          elevation: 10, // 그림자의 깊이 조절
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(100),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 10),
                                        ),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment(0.00, -1.00),
                                              end: Alignment(0, 1),
                                              colors: [
                                                Color(0xFFCFCFFB),
                                                Color(0xFFE7E7FF)
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20.0),
                                          ),
                                          child: Container(
                                            constraints: BoxConstraints(
                                                minWidth: 160, minHeight: 48),
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                SizedBox(
                                                  width: 100,
                                                ),
                                                Icon(
                                                    CupertinoIcons
                                                        .hand_point_right_fill,
                                                    color: Colors.amber),
                                                Text(
                                                  " ${thirdBadFrameTime.toStringAsFixed(2)} ~ ${(thirdBadFrameTime + 3).toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 24,
                                                      color: Colors.black),
                                                ),
                                                SizedBox(
                                                  width: 100,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20.0),
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Color.fromRGBO(255, 255, 255, 20),
                                      shadowColor: Colors.transparent,
                                      elevation: 10, // 그림자의 깊이 조절
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 50, horizontal: 40),
                                    ),
                                    child: Row(
                                      children: [
                                        Image.file(
                                          File(snapshot.data![2]),
                                          width: 100,
                                          height: 190,
                                        ),
                                        SizedBox(width: 30),
                                        SizedBox(
                                          width: 150,
                                          // height: 70,
                                          child: Text(
                                            '다리의 움직임에 조금 더 주의를 기울여 보세요!',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 20,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 200,
                              height: 50,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'A.dance Evaluation Report\n',
                                          style: TextStyle(
                                            color: Color(0xFF9EA3B1),
                                            fontSize: 13,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Produced by 에이닷',
                                          style: TextStyle(
                                            color: Color(0xFF9EA3B1),
                                            fontSize: 10,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
            }),
      ),
    );
  }
}
