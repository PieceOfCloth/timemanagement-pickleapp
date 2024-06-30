import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

class Pickle extends StatelessWidget {
  const Pickle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(
        top: 100,
        left: 10,
        right: 10,
        bottom: 10,
      ),
      child: IntroductionScreen(
        pages: [
          PageViewModel(
            title: "Learning About Pickle Jar Theory Time Management",
            body:
                "Let's explore the pickle jar theory—a powerful metaphor for effective time management and prioritization in daily life.",
            image: Image.asset(
              'assets/app-logo.png',
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
            ),
          ),
          PageViewModel(
            title: "The Empty Jar",
            body:
                "Imagine an empty jar is represents your day, starting with potential to be filled with various tasks.",
            image: Image.asset(
              'assets/empty-jar.png',
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
            ),
          ),
          PageViewModel(
            title: "Golf Balls, Pebbles, Sand, and Water",
            body:
                "Golf balls is stand for crucial task that need to be done ASAP, Pebbles is a important but secondary tasks that not too urgent, Sand is a trivial activities like social media, Water is a flexible activities like hobbies and spontaneous fun that can leave us to procastination.",
            image: Image.asset(
              'assets/golf-pebbles-sand-water.png',
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
            ),
          ),
          PageViewModel(
            title: "Jar Full of Golf Balls",
            body:
                "Imagine if we have a jar filled only with golf balls (CRUCIAL Task). It will leaves us a gaps for a necessary activities and potential BURNOUT.",
            image: Image.asset(
              'assets/golf-jar.png',
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
            ),
          ),
          PageViewModel(
            title: "Jar Full of Pebbles",
            body:
                "Now Imagine if we also have a jar full of pebbles (SECOND IMPORTANT Task). There is will be NO ROOM FOR THE MOST IMPORANT Task that must to be done, resulting in a BIG MAJOR PROBLEM.",
            image: Image.asset(
              'assets/pebbles-jar.png',
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
            ),
          ),
          PageViewModel(
            title: "Jar Full of Sand",
            body:
                "Also if we have a jar filled with full of sand that usually shows a day consumed by trivial activities like social media. it leave us no room for important tasks like work or exercise, leading to procrastination and unproductiveness.",
            image: Image.asset(
              'assets/sand-jar.png',
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
            ),
          ),
          PageViewModel(
            title: "Jar Full of Water",
            body:
                "The last, if we have a jar filled with water which only focuses on flexible activities like hobbies and SPONTANEOUS Task. It will leave us ignored our tasks and responsibilities. which can  CAUSE CHAOS AND INEFFICIENCY in our daily life.",
            image: Image.asset(
              'assets/water-jar.png',
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
            ),
          ),
          PageViewModel(
            title: "Balanced Jar",
            body:
                "A balanced jar includes golf balls, pebbles, sand, and water, may ensuring us prioritize crucial tasks, handle secondary responsibilities, manage minor activities, and allow for spontaneous task. It can make us to maximizing productivity and satisfaction.",
            image: Image.asset(
              'assets/full-jar.png',
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
            ),
          ),
        ],
        showSkipButton: false,
        showDoneButton: false,
        showNextButton: false,
        dotsDecorator: DotsDecorator(
          size: const Size.square(10.0),
          activeSize: const Size(22.0, 10.0),
          activeColor: const Color.fromARGB(255, 3, 0, 66),
          color: Colors.grey,
          spacing: const EdgeInsets.symmetric(horizontal: 1.0),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      ),
    );
  }
}
