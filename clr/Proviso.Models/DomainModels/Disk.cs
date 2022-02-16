using System.Collections.Generic;
using System.Linq;

namespace Proviso.DomainModels
{
    public class Disk
    {
        public int DiskNumber { get; private set; }             // => Config.ExpecteDisks.XXX.PhysicalDiskIdentifiers.DiskNumber
        public string VolumeId { get; private set; }            // => Config.ExpecteDisks.XXX.PhysicalDiskIdentifiers.VolumeId
        public string ScsiMapping { get; private set; }         // => Config.ExpecteDisks.XXX.PhysicalDiskIdentifiers.ScsiMapping    
        public string DeviceId { get; private set; }            // => Config.ExpecteDisks.XXX.PhysicalDiskIdentifiers.DeviceId
        public string Path { get; private set; }
        
        public int SizeInGBs { get; private set; }              // => Config.ExpecteDisks.XXX.PhysicalDiskIdentifiers.RawSize

        public List<Partition> Partitions { get; private set; }

        public bool IsInitialized => (this.Partitions.Any(p => p.VolumeName != null));

        // vNEXT: add these? (with defaults?)
        //public int AllocationUnitSize { get; private set; }
        //public bool LargeFRS { get; private set; }

        public Disk(int diskNumber, string volumeId, string scsiMapping, string deviceId, string path, int size)
        {
            this.DiskNumber = diskNumber;
            this.VolumeId = volumeId;
            this.ScsiMapping = scsiMapping;
            this.DeviceId = deviceId;
            this.Path = path;
            this.SizeInGBs = size;
            
            this.Partitions = new List<Partition>();
        }

        public void AddPartition(Partition partition)
        {
            this.Partitions.Add(partition);
            partition.SetParent(this);
        }
    }
}