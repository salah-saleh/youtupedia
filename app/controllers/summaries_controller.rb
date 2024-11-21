class SummariesController < ApplicationController
  def show
    @summary = {
      title: "BEATEN ONLY 3 TIMES IN 14 YEARS! | OL' SOUTH'S 10LB PANCAKE CHALLENGE | BeardMeatsFood",
      channel: "BeardMeatsFood",
      date: "4 Dec 2022",
      time: "13:21",
      rating: 4.9,
      votes: 33,
      video_id: "dQw4w9WgXcQ",  # This is just a placeholder YouTube video ID
      tldr: "In this entertaining food challenge at Old South Pancake House in Fort Worth, Texas, a man attempts the infamous 10-pound pancake stack, a feat only three people have completed. Despite starting with determination, the massive size of the pancakes proves overwhelming. With only 60 minutes to finish, he struggles physically and mentally, battling the bulk and texture of the pancakes. Though he doesn't succeed, the experience leaves him reflecting on the journey and embracing the lesson in failure, humor, and growth. A light-hearted yet challenging tale of attempting the impossible.",
      takeaways: [
        "The speaker recently achieved second place in a pancake challenge, winning $1,000 for their efforts.",
        "The location of the challenge is in Fort Worth, Texas, which the speaker compares to the proximity of Leeds and Bradford in the UK."
      ],
      tags: [
        "Pancake Challenge", "Fort Worth", "Food Challenge", "Texas",
        "Epic Fail", "Foodie Adventure", "Competitive Eating",
        "Restaurant Challenge", "Old South Pancake House", "Humor", "Viral Video"
      ]
    }
  end
end
