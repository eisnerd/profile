using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;

namespace wmatags.CLI
{
	public class FileList
	{
		public static string pat = "*.wma";
		public delegate R Function<R>();
		public static IEnumerable<T> UntilNull<T>(Function<T> f)
		{
			T t;
			while ((t = f()) != null)
				yield return t;
		}
		public static IEnumerable<string> Files(IEnumerable<string> paths)
		{	
			foreach (string path in paths)
				if (Directory.Exists(path))
				{
					foreach (string sub in Files(Directory.GetFiles(path, pat)))
						yield return sub;
					foreach (string sub in Files(Directory.GetDirectories(path)))
						yield return sub;
				}
				else if (File.Exists(path))
					yield return path;
				else if (path == "-")
					foreach (string sub in Files(UntilNull<string>(Console.ReadLine)))
						yield return sub;
		}
	}
	
	public class TrackFromPath : FileList
	{
		public static void Main(string[] args)
		{
			int i; uint j;
			foreach (string path in Files(args))
				if ((i = Path.GetFileName(path).IndexOf(' ')) > 0 && uint.TryParse(Path.GetFileName(path).Substring(0, i), out j))
			{
				Console.WriteLine(path + ": " + j);
				TagLib.Asf.File file = new TagLib.Asf.File(path);
				file.Tag.Track = j;
				file.Save();
			}
		}
	}
}