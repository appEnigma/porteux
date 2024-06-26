#!/bin/sh

DownloadAndReturn() {
    contentDisposition=$(wget --server-response --content-disposition $url 2>&1 | grep -i "content-disposition:")

    filename=${contentDisposition#*filename=}
    version="${version//[^0-9._-]/}"
    
    echo "$filename $version"
}

GetLatestTagFromGithub() {
    repository="$1"
    project="$2"

    if [ ! "$version" ]; then
        tagInfo=$(curl -s https://api.github.com/repos/"$repository"/"$project"/tags)
        version=$(echo "$tagInfo" | tr ',' '\n' | grep "\"name\":" | cut -d \" -f 4 | grep -v "alpha" | grep -v "beta" | sort -V -r | head -n 1)
    fi
    
    url=https://github.com/"$repository"/"$project"/archive/refs/tags/$version.tar.gz
}

DownloadLatestSourceFromGithub() {
    repository="$1"
    project="$2"
    filename=
    version=
    url=
    
    GetLatestTagFromGithub "$repository" "$project"
    DownloadAndReturn
}

DownloadLatestFromGithub() {
    repository="$1"
    project="$2"
    filename=
    version=
    url=

    releaseInfo=$(curl -s https://api.github.com/repos/"$repository"/"$project"/releases)
    version=$(echo "$releaseInfo" | tr ',' '\n' | grep "\"tag_name\":" | cut -d \" -f 4 | grep -v "alpha" | grep -v "beta" | grep -E -v "\-rc[0-9]" | sort -V -r | head -n 1)
    url=$(echo "$releaseInfo" | tr ',' '\n' | grep ".tar" | grep -v ".asc" | grep -v ".sha256" | grep "\"browser_download_url\":" | grep "$version" | grep -v "alpha" | grep -v "beta" | grep -E -v "\-rc[0-9]" | cut -d \" -f 4 | head -n 1)
    
    # if there are no releases available, try to get from 'tags'
    if [ ! "$url" ]; then
        GetLatestTagFromGithub "$repository" "$project"
    fi

    DownloadAndReturn
}
