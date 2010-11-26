using System;

namespace wmatags.CLI
{
	public class Read : FileList
	{
		public static void ReadTo(System.IO.TextWriter w, string path)
		{
				using(TagLib.File file = TagLib.File.Create(path))
				foreach (System.Reflection.PropertyInfo prop in file.Tag.GetType().GetProperties())
				{
					w.Write(prop.Name);
					w.Write(": ");
					object o = prop.GetValue(file.Tag, null);
					w.WriteLine(o);
					if (o is System.Collections.IEnumerable && !(o is string))
					foreach (object v in (o as System.Collections.IEnumerable))
					{
						w.WriteLine("\t"+v);
					}
				}
		}
		public static void Main(string[] args)
		{
			foreach (string path in Files(args))
				using (System.IO.Stream s = System.IO.File.OpenWrite(System.IO.Path.Combine(System.IO.Path.GetDirectoryName(path), System.IO.Path.GetFileNameWithoutExtension(path)+".tag")))
					using (System.IO.TextWriter meta = new System.IO.StreamWriter(s))
			{
						//ReadTo(Console.Out, path);
						ReadTo(meta, path);
			}
		}
	}
}
