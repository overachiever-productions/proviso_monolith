namespace Proviso.DomainModels
{
    public class Partition
    {
        public Disk Parent { get; private set; }
        public int PartitionNumber { get; private set; }
        public int PartitionSize { get; private set; }

        public string VolumeName { get; private set; }
        public string VolumeLabel { get; private set; }

        public Partition(int number, int size, string volume)
        {
            this.PartitionNumber = number;
            this.PartitionSize = size;
            this.VolumeName = volume;
        }

        public void SetParent(Disk parent)
        {
            this.Parent = parent;
        }

        public void AddLabel(string label)
        {
            this.VolumeLabel = label;
        }
    }
}