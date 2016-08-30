git rev-parse --is-inside-work-tree 2>/dev/null >/dev/null
if [[ $? -ne 0 ]]; then
  echo "you are not in a git working tree,quitting"
  exit
fi
user_repo=origin
stayzilla_repo=upstream
fork_url=$(git remote get-url --all $user_repo)
if [[ $? -ne 0 ]]; then
  echo "remote $user_repo is not set,please use git remote add $user_repo <your forked repo address>"
  exit
fi
if [[  $fork_url =~ "/stayzilla/" ]]; then
  echo "$user_repo repo can't point stayzilla,please set it to your fork, get remote set-url $user_repo <your forked repo address>";
  exit
fi
stayzilla_repo_url=$(git remote get-url --all $stayzilla_repo)
if [[ $? -ne 0 ]]; then
  echo "remote $stayzilla_repo is not set,please use git remote add $stayzilla_repo <stayzilla repo address>"
  exit
fi
if [[ ! $stayzilla_repo_url =~ "/stayzilla/" ]]; then
  echo "$stayzilla_repo  repo must be stayzilla repo, git remote set-url $stayzilla_repo <stayzilla repo address>";
  exit
fi

while getopts ":f:b:a:" opt; do
  case "${opt}" in
    f)
      feature_name=${OPTARG}
      ;;
    b)
      fork_branch_name=${OPTARG}
      ;;
    a)
      action=${OPTARG}
      ;;
    *)
      ;;
  esac
done
if [[ -z $action ]];then
  echo "action can't be empty"
  exit 1
fi
if [[ $action == "done" ]];then
  feature_branch=$(git rev-parse --abbrev-ref HEAD)
  if [[ ! $feature_branch =~ "_fb_" ]]; then
    echo "current branch is not a feature branch,will not push it,quitting.To push manually use git push $user_repo $feature_branch."
    exit
  fi

  local_parent_branch=$(echo ${feature_branch} | awk -F '/' '{print $2}' | cut -d\- -f1)
  echo "Merging latest $stayzilla_repo/$local_parent_branch to local $local_parent_branch"
  git checkout $local_parent_branch
  git fetch $stayzilla_repo
  git merge $stayzilla_repo/$local_parent_branch
  git checkout $feature_branch 
  echo "Rebasing local $feature_branch against latest local $local_parent_branch"
  git rebase $local_parent_branch
  echo "Going to push local/$feature_branch to $user_repo/$feature_branch"
  git push $user_repo $feature_branch
  exit 
fi
if [[ $action == "new" ]]; then
  if [ -z "${feature_name}" ] || [ -z "${fork_branch_name}" ]  ; then
    echo "both feature_name and a  remote branch  and user_repo must be  provided"
    exit 
  fi
  git show-ref --verify refs/remotes/$user_repo/${fork_branch_name} --quiet
  if [[ $? -ne 0 ]]; then
    echo "${fork_branch_name} does not exist in remote ${user_repo},quitting"
    exit
  fi
  git show-ref --verify refs/heads/${fork_branch_name} --quiet
  if [[ $? -ne 0 ]]; then
    echo "${fork_branch_name} does not exist in local disk,creating it and tracking ${user_repo}/${fork_branch_name}"
    git checkout -b ${fork_branch_name} -t ${user_repo}/${fork_branch_name}
  else
    echo "Checking out ${fork_branch_name}"
    git checkout ${fork_branch_name}
  fi
  echo "Fetching stayzilla repo"
  git fetch $stayzilla_repo
  echo "updating local ${fork_branch_name} from $stayzilla_repo/${fork_branch_name}"
  git merge $stayzilla_repo/${fork_branch_name} #merge stayzilla master changes to local master
  echo "pushing local ${fork_branch_name} to $user_repo/${fork_branch_name}"
  git push $user_repo ${fork_branch_name} #push  update local master to fork(just to avoid that message)
  timestamp=$(date +'%Y%m%d_%H%M%S')
  new_branch_name=_fb_${feature_name}_from_${user_repo}/${fork_branch_name}-$timestamp
  echo "creating feature branch ${new_branch_name} on local"
  git branch $new_branch_name #create a new branch from our local master
  git checkout $new_branch_name #shift to the new branch
  exit
fi
echo "unknown option passed in action"
exit
