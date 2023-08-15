library(spotifyr)
library(dplyr)
library(writexl)
library(readxl)

########################### SETTING UP SPOTIFYR ################################
Sys.setenv(SPOTIFY_CLIENT_ID = client_id)
Sys.setenv(SPOTIFY_CLIENT_SECRET = client_secret)
access_token <- get_spotify_access_token()


########################## GETTING J-POP ARTISTS ###############################
jpop_artists <- get_genre_artists("j-pop", market="JP", limit=50, offset=0)

offsets <- seq(from=50, to=1000-50, by=50)
for (i in offsets){
  artist_out <- get_genre_artists("j-pop", market="JP", limit=50, offset=i)
  jpop_artists <- rbind(jpop_artists, artist_out)
}

colnames(jpop_artists)
drop_cols = c(
  href, "images", "type", "uri", "external_urls.spotify", "followers.href"
) 
# dropping irrelevant columns
jpop_artists <- jpop_artists[,!names(jpop_artists) %in% drop_cols]

# dropping irrelevant rows (non j-pop artists)
# manually went through and noted indices :-(
delete <- c(994, 993, 987, 984, 982, 978, 972, 969, 962, 951, 936, 935, 929, 
            926, 916, 914, 913, 900, 895, 898, 891, 888, 859, 850, 828, 827, 
            811, 809, 797, 789, 774, 761, 733, 586, 585, 580, 498)

jpop_artists <- jpop_artists[-delete,]


########################## GETTING TRACKS FROM ARTISTS #########################
track_uri_list <- list()

get_artist_track_uris_safe <- function(artist_id) {
  all_tracks <- tryCatch({
    get_artist_audio_features(artist_id)
  }, error = function(e) {
    message(paste("No albums found with artist_id='", artist_id, "'.Skipping..."))
    return(NULL)
  })
  return(all_tracks)
}

drop_cols_artists = c(
  "album_type", "album_images", "album_release_date", "album_release_year", 
  "album_release_date_precision","available_markets", "disc_number", 
  "track_href", "is_local", "track_preview_url", "track_number", "type", 
  "track_uri", "external_urls.spotify", "album_name", "key_name", "mode_name", 
  "key_mode", "album_id", "artists", "analysis_url"
)

n = length(jpop_artists$id)
artist_ids <- jpop_artists$id[1:floor(n/2)]
# only first half, technically [ceiling(n/2):n] hasn't been requested yet
# so if you want a bigger dataset... go for it
track_uri_list <- lapply(artist_ids, get_artist_track_uris_safe)
track_uris <- do.call(rbind, track_uri_list)

track_uris <- track_uris[,!names(track_uris) %in% drop_cols_artists]

jpop_artists <- jpop_artists %>%
  rename("artist_id" = "id", 
         "artist_popularity" = "popularity",
         "artist_followers" = "followers.total")

merged <- left_join(
  track_uris, 
  select(jpop_artists, artist_id, artist_popularity, artist_followers), 
  by = "artist_id"
)

count_nulls_in_list <- function(lst) {
  sum(sapply(lst, is.null))
}
count_nulls_in_lol <- function(list_of_lists) {
  sapply(list_of_lists, count_nulls_in_list)
}
merged_nullcount <- count_nulls_in_lol(merged)

write_xlsx(merged, "merged.xlsx")


########################## GETTING TRACK POPULARITY ############################
merged <- read_excel("merged.xlsx")

get_popularity <- function(track_id) {
  track_info <- get_track(track_id)
  return(track_info$popularity)
}
get_popularity_delay <- function(track_id) {
  popularity <- NULL
  while (is.null(popularity)) {
    tryCatch({
      popularity <- get_popularity(track_id)
    }, error = function(e) {
      Sys.sleep(1)
    })
  }
  return(popularity)
}

track_ids <- merged$track_id
n_tracks <- length(merged$track_id)

seq_float <- seq.int(from=1, to=n_tracks, length.out=11)
seq_int <- unlist(lapply(seq_float, floor))

idx <- c(
  seq_int[1], seq_int[2]-1, 
  seq_int[2], seq_int[3]-1, 
  seq_int[3], seq_int[4]-1, 
  seq_int[4], seq_int[5]-1, 
  seq_int[5], seq_int[6]-1, 
  seq_int[6], seq_int[7]-1, 
  seq_int[7], seq_int[8]-1, 
  seq_int[8], seq_int[9]-1, 
  seq_int[9], seq_int[10]-1, 
  seq_int[10], seq_int[11]
)

# i know this looks really ugly, but it was the best way i could think of
# given the api daily and 30-second-interval limits :/ 
track_pop_lst1 <- lapply(track_ids[idx[1]:idx[2]], get_popularity_delay)
track_pop_lst2 <- lapply(track_ids[idx[3]:idx[4]], get_popularity_delay)
track_pop_lst3 <- lapply(track_ids[idx[5]:idx[6]], get_popularity_delay)
track_pop_lst4 <- lapply(track_ids[idx[7]:idx[8]], get_popularity_delay)
track_pop_lst5 <- lapply(track_ids[idx[9]:idx[10]], get_popularity_delay)
track_pop_lst6 <- lapply(track_ids[idx[11]:idx[12]], get_popularity_delay)
track_pop_lst7 <- lapply(track_ids[idx[13]:idx[14]], get_popularity_delay)
track_pop_lst8 <- lapply(track_ids[idx[15]:idx[16]], get_popularity_delay)
track_pop_lst9 <- lapply(track_ids[idx[17]:idx[18]], get_popularity_delay)
track_pop_lst10 <- lapply(track_ids[idx[19]:idx[20]], get_popularity_delay)

track_pop1 <- unlist(track_pop_lst1)
track_pop2 <- unlist(track_pop_lst2)
track_pop3 <- unlist(track_pop_lst3)
track_pop4 <- unlist(track_pop_lst4)
track_pop5 <- unlist(track_pop_lst5)
track_pop6 <- unlist(track_pop_lst6)
track_pop7 <- unlist(track_pop_lst7)
track_pop8 <- unlist(track_pop_lst8)
track_pop9 <- unlist(track_pop_lst9)
track_pop10 <- unlist(track_pop_lst10)

track_pop_full <- c(
  track_pop1, track_pop2, track_pop3, track_pop4, track_pop5,
  track_pop6, track_pop7, track_pop8, track_pop9, track_pop10
)


####################### ADDING TRACK POPULARITY TO BIG DF ######################
merged$track_popularity <- track_pop_full
write_xlsx(merged, "final_songs.xlsx")