FROM ruby:2.3.3

RUN apt-get update -qq && apt-get install -y apt-utils

# Install gems
ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install

# Upload source
ADD . $APP_HOME

# Start server
ENV PORT 4567
EXPOSE 4567
