// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "credential"
import "messenger"

import "chartkick"
import "Chart.bundle"

import Rails from "@rails/ujs";

Rails.start();
