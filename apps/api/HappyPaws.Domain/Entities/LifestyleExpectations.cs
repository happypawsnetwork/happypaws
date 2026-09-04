using System.Collections.Generic;
using HappyPaws.Domain.Enums;

namespace HappyPaws.Domain.Entities;

public class LifestyleExpectations
{
    public HomeSize? HomeSize { get; set; }
    public bool RequiresEnclosedYard { get; set; }
    public bool GoodWithChildren { get; set; } = true;
    public ActivityTempo? ActivityTempo { get; set; }
    public List<string> GoodWithPets { get; set; } = new();
}
