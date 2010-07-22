using System.Collections.Generic        ;
public class WriteTags
        {
                public static void Main(string[] args)
                {
			using(TagLib.File f = TagLib.File.Create(args[0]))
			{
				string c = (System.Console.ReadLine()??"");
				if (c != null)
					c += ": ";
				string a = (System.Console.ReadLine()??"");
				
				f.Tag.Track = uint.Parse(System.Console.ReadLine());
				f.Tag.Title = System.Console.ReadLine()??"";
				f.Tag.Album = System.Console.ReadLine()??"";
					if (f.Tag.Album.EndsWith(f.Tag.Title))
						f.Tag.Album = f.Tag.Album.Remove(f.Tag.Album.Length - f.Tag.Title.Length).Trim(".:; ".ToCharArray());
					if (f.Tag.Album == f.Tag.Title || string.IsNullOrEmpty(f.Tag.Album))
						f.Tag.Album = a;
					else if (f.Tag.Title.StartsWith(f.Tag.Album) && f.Tag.Title.Length > f.Tag.Album.Length)
						f.Tag.Title = f.Tag.Title.Substring(f.Tag.Album.Length);
					if (!f.Tag.Album.ToLower().Contains(c.ToLower()))
						f.Tag.Album = c + f.Tag.Album;
				string artist = null, next;
				List<string> artists = new List<string>();
				while ((next = System.Console.ReadLine()) != null)
				{
					artist = string.IsNullOrEmpty(artist)? next : (artist + "; " + next);
					artists.Add(next);
				}
				f.Tag.Artists = artists.ToArray();
				f.Tag.AlbumArtists = artists.ToArray();
				//if (!string.IsNullOrEmpty(artist))
					//f.Tag.JoinedArtists = artist;
				f.Save();
			}
		}
	}

