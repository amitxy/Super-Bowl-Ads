import pandas as pd
from pytube import YouTube
#from moviepy.editor import VideoFileClip

#df = pd.read_excel(r"C:567superbowl-ads.xlsx")
#for url in df['youtube_url']:
    #yt = YouTube(url)
    #duration = yt.length
   # df['Duration'] = [duration for url in df['youtube_url']]
    #df.to_excel(r"C:/Users/User/Ilan/statisticsProject/superbowl-ads.xlsx", index=False)


#video_url = "https://www.youtube.com/watch?v=zeBZvwYQ-hA#"  # Replace VIDEO_ID with the actual video ID or link
#yt = YouTube(video_url)
#duration = yt.length

#print(f"Video Duration: {duration} seconds")

import pandas as pd
from pytube import YouTube

# Read Excel file
df = pd.read_excel(r'C:\\Users\\User\\Ilan\\statisticsProject\\uga buga.xlsx')

# Extract durations from YouTube links
durations = []
for link in df['youtube_url']:
    try:
        yt = YouTube(link)
        duration = yt.length
        durations.append(duration)
    except:
        durations.append(None)  # Handle errors if the link is invalid or the video is not accessible

# Add durations to the DataFrame
df['Duration'] = durations

# Save the updated DataFrame to Excel
df.to_excel(r'C:\\Users\\User\\Ilan\\statisticsProject\\uga buga.xlsx', index=False)