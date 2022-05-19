[CmdletBinding(SupportsShouldProcess)]
param(
  # The repo owner: e.g. Azure
  $RepoOwner,
  # The repo name. E.g. azure-sdk-for-java
  $RepoName,
  # Please use the RepoOwner/RepoName format: e.g. Azure/azure-sdk-for-java
  $RepoId="$RepoOwner/$RepoName",
  # CentralRepoId the original PR to generate sync PR. E.g Azure/azure-sdk-tools for eng/common
  $CentralRepoId,
  # We start from the sync PRs, use the branch name to get the PR number of central repo. E.g. sync-eng/common-(<branchName>)-(<PrNumber>). Have group name on PR number.
  $CentralPRRegex,
  # Date format: e.g. Tuesday, April 12, 2022 1:36:02 PM. Allow to use other date format.
  [AllowNull()]
  [DateTime]$LastCommitOlderThan,
  [switch]$skipCentralPR,
  [Parameter(Mandatory = $true)]
  $AuthToken
)

. (Join-Path $PSScriptRoot common.ps1)

function RetrievePRAndClose {
  [CmdletBinding(SupportsShouldProcess)]
  param (
    $pullRequestNumber
  )

  if (!$pullRequestNumber) {
    return $false
  }
  try {
    Write-Host "The repo [ $CentralRepoId ] pull request number is [ $pullRequestNumber ] "
    $centralPR = Get-GitHubPullRequest -RepoId $CentralRepoId -PullRequestNumber $pullRequestNumber -AuthToken $AuthToken
    if ($centralPR.state -ne "closed") {
      return $true
    }
  }
  catch 
  {
    LogError "Get-GitHubPullRequests failed with exception:`n$_"
    return $false
  }
  
  try {
    $head = "${RepoId}:${branchName}"
    LogDebug "Operating on branch [ $branchName ]"
    $pullRequests = Get-GitHubPullRequests -RepoId $RepoId -State "all" -Head $head -AuthToken $AuthToken
  }
  catch
  {
    LogError "Get-GitHubPullRequests failed with exception:`n$_"
    exit 1
  }
  $openPullRequests = $pullRequests | ? { $_.State -eq "open" }

  foreach ($openPullRequest in $openPullRequests) {
    try 
    {
      if (!$hasCentralPROpened -and $PSCmdlet.ShouldProcess("[ $($openPullRequest.url)] with branch [ $branchName ] in [ $RepoId ]", "Closing the pull request")) {
        Close-GithubPullRequest -apiurl $openPullRequest.url -AuthToken $AuthToken | Out-Null
        LogDebug "Open pull Request [ $($openPullRequest.url)] associate with branch [ $branchName ] in repo [ $RepoId ] has been closed."
      }
    }
    catch
    {
      LogError "Close-GithubPullRequest failed with exception:`n$_"
      exit 1
    }
  }
  return $false
}

LogDebug "Operating on Repo [ $RepoId ]"

try{
  # pull all branches.
  $responses = Get-GitHubSourceReferences -RepoId $RepoId -Ref "heads" -AuthToken $AuthToken
}
catch {
  LogError "Get-GitHubSourceReferences failed with exception:`n$_"
  exit 1
}

foreach ($res in $responses)
{
  if (!$res -or !$res.ref) {
    LogDebug "No branch returned from the branch prefix $CentralPRRegex on $Repo. Skipping..."
    continue
  }
  $branch = $res.ref
  $branchName = $branch.Replace("refs/heads/","")
  if (!($branchName -match $CentralPRRegex)) {
    continue
  }
  $hasCentralPROpened = $false
  if (!$skipCentralPR) {
    $hasCentralPROpened = RetrievePRAndClose -pullRequestNumber $Matches["PrNumber"] 
  }
  if ($LastCommitOlderThan) {
    if (!$res.object -or !$res.object.url) {
      LogWarning "No commit url returned from response. Skipping... "
      continue
    }
    try {
      $commitDate = Get-GithubReferenceCommitDate -commitUrl $res.object.url -AuthToken $AuthToken
      if (!$commitDate) {
        LogDebug "No last commit date found. Skipping."
        continue
      }
      if ($commitDate -gt $LastCommitOlderThan) {
        LogDebug "The branch $branch last commit date [ $commitDate ] is newer than the date $LastCommitOlderThan. Skipping."
        continue
      }
      
      LogDebug "Branch [ $branchName ] in repo [ $RepoId ] has a last commit date [ $commitDate ] that is older than $LastCommitOlderThan. "
    }
    catch {
      LogError "Get-GithubReferenceCommitDate failed with exception:`n$_"
      exit 1
    }
  } 
  
  try {
    if (!$hasCentralPROpened -and $PSCmdlet.ShouldProcess("[ $branchName ] in [ $RepoId ]", "Deleting branches on cleanup script")) {
      #Remove-GitHubSourceReferences -RepoId $RepoId -Ref $branch -AuthToken $AuthToken
      LogDebug "The branch [ $branchName ] in [ $RepoId ] has been deleted."
    }
  }
  catch {
    LogError "Remove-GitHubSourceReferences failed with exception:`n$_"
    exit 1
  }
}
