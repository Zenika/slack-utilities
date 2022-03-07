$token = "A token from a Slack app with channels:read and channels:write auth";
$stats = Import-Csv 'An export from Slack Analytics.csv'
$zombies = $stats | ? {($_."Full Members" -le 1) -or ([Datetime]$_.'Last active' -le (get-date).AddMonths(-6)) -or ($_."Messages Posted" -eq 0) }

$cursor = $null;
$channels = $null;
do {
	$channelsResponse = Invoke-RestMethod https://slack.com/api/conversations.list -Headers @{Authorization=$token} -Body @{limit=1000;cursor=$cursor}
	$channels += $channelsResponse.channels
	$cursor = $channelsResponse.response_metadata.next_cursor
} while($cursor)

$channels | % {$idsByName = @{}} {$idsByName[$_.name] = $_.id}


$toDo = {
	Write-host "Archiving $($_.name)"
	$id = $idsByName[$_.name]
	$apiResult = Invoke-RestMethod https://slack.com/api/conversations.archive -Headers @{Authorization=$token} -Body @{channel=$id}
	$result = @{Name=$_.name;Id=$id;Ok=$apiResult.ok;Error=$apiResult.error}
	new-object -property $result -type PsObject
	Write-host "Done archiving $($_.name) with result $($result.ok) and eventual error: $($result.error)"
	Start-Sleep 3
}

$archiving = $zombies | foreach-object $toDo


