require 'rest-client'
require 'octokit'
require 'csv'
=begin
begin
res = RestClient.get("https://api.github.com/orgs/stayzilla/teams/access_token=8d5c9a65c04112ca0e3d3f4586ca17a697b4746c")
p res.body
rescue Exception => e 
  p e.message
  p e.response
end
=end
token = ENV['GITHUB_STAYZILLA_ACCOUNT_TOKEN']
client =  Octokit::Client.new(:access_token => token)
client.auto_paginate = true
CSV.open("file.csv","w+") do |csv|
  teams = client.org_teams("stayzilla")
  repos_p = client.org_repos("stayzilla")
  
  teams.each do |team|
    team_id = team.id
    team_name = team.name
    repos = client.team_repos(team_id)
    team_repos = []
    team_repos.push team_name
    repos.each do |repo|
      repo_name = repo.full_name
      if repo_name.match(/stayzilla/) and repo.permissions.push == true
        team_repos.push repo_name
      end
    end
    p "teams"
    csv << team_repos 
  end

  teams.each do |team|
    team_id = team.id
    team_name = team.name
    team_users = []
    team_users.push team_name
    users = client.team_members(team_id)
    team_users+= users.map{|user| user.login}
    p "users"
    csv << team_users
  end


  repos_p.each do |repo|
    repo_name = repo.full_name
    teams = client.teams(repo_name)
    team_names = []
    team_names.push repo_name
    team_names += teams.map{|team| team.name}
    p "repos"
    csv << team_names
  end
end

