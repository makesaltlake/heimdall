web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e production
worker: bundle exec inst_jobs run
release: bin/do-release-tasks
