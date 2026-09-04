using System.Collections.Generic;
using HappyPaws.Domain.Enums;

namespace HappyPaws.Domain.Entities;

public class LifestyleProfile
{
    public HomeSize? HomeSize { get; set; }
    public bool HasEnclosedYard { get; set; }
    public bool HasChildren { get; set; }
    public ActivityTempo? ActivityTempo { get; set; }
    public List<string> ExistingPets { get; set; } = new();
}
