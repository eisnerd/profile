using System.Collections.Generic        ;
public class WriteTags
        {
                public static void Main(string[] args)
                {
			string next = null, file;
			while ((next = next??System.Console.ReadLine()) != null)
				if (next.StartsWith("::") && (file = next.Substring(2)) != null)
			try
			{
			using(TagLib.File f = TagLib.File.Create(file))
			{
				f.Tag.Composers = new string[] { System.Console.ReadLine()??"" };
				f.Tag.Album = System.Console.ReadLine()??"";
				f.Tag.Track = uint.Parse(System.Console.ReadLine());
				f.Tag.Title = System.Console.ReadLine()??"";
				string a = System.Console.ReadLine()??"";
				f.Tag.Artists = new string[] { a };
				f.Tag.AlbumArtists = new string[] { a };
				f.Save();
			}
			}
			catch(System.Exception exc)
			{
				System.Console.WriteLine(exc);
			}
			finally
			{
				System.Console.WriteLine(file);
				next = null;
			}
			else next = null;
		}
	}

