#!/bin/bash

git checkout hotspot.config openj9.config hotspot-official.config openj9-official.config

sed '/^Directory: .*/i OS_Family: linux' hotspot.config | sed '/^Directory: .*windows.*/i OS_Family: windows' | sed -z 's/OS_Family: linux\nOS_Family: windows/OS_Family: windows/g' > h.config
sed '/^Directory: .*/i OS_Family: linux' hotspot-official.config | sed '/^Directory: .*windows.*/i OS_Family: windows' | sed -z 's/OS_Family: linux\nOS_Family: windows/OS_Family: windows/g' > h-o.config

sed '/^Directory: .*/i OS_Family: linux' openj9.config | sed '/^Directory: .*windows.*/i OS_Family: windows' | sed -z 's/OS_Family: linux\nOS_Family: windows/OS_Family: windows/g' > o.config
sed '/^Directory: .*/i OS_Family: linux' openj9-official.config | sed '/^Directory: .*windows.*/i OS_Family: windows' | sed -z 's/OS_Family: linux\nOS_Family: windows/OS_Family: windows/g' > o-o.config

cp h.config hotspot.config
cp h-o.config hotspot-official.config
cp o.config openj9.config
cp o-o.config openj9-official.config
