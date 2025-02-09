

TODO BEFORE LAUNCH:
- stats: limit number of videos per user per day for start
- nginx https://elements.heroku.com/buildpacks/heroku/heroku-buildpack-nginx 
- schedular [text](https://devcenter.heroku.com/articles/scheduler)
- [ ] more analytics on logged in users:admin and active users



TODO AFTER LAUNCH:
- statistics page
- [ ] payements
- [ ] use resque for job management
- [ ] implement prober queing
- [ ] handling requests async https://www.youtube.com/watch?v=QeYcKw7nOkg&ab_channel=RubyCentral
- [ ] explore cacheing on fragmnets https://guides.rubyonrails.org/caching_with_rails.html
- [ ] Add manifest settings for PWA support
- [ ] look to the logs and optimize things based on analysis of composer
- [ ] logs.rake do provide more analysis average per route, p95, p99, max,etc.


Features:
- [ ] discovery tap (based on your keywords, it suggests latest youtube videos to watch and summarize), works with concept of collections



costs:
- Domain namecheap:
    - youtupedia: 89euros/year
        - starter email: free
    - y2si: 16euros/year
- Heroku:
    - dyno standard: 5euros/month (needs to be upgraded soon)
    - memcached (25MB/10connections): free (needs to be upgraded to 15euros/month )
    - Postgress: 5euros/month
- postmarkapp:
    - 100 emails/month: free (upgrade needed 15euros/month)
- Mongodb:
    - 100MB/month: free
- AI:
    - Google Flash: free
    - ChatGPT: free
- Google APIs:
    - Youtube: free 

