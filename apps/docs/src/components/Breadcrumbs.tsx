import { useLocation, Link } from "react-router";
import { ChevronRight, Home, Code2 } from "lucide-react";
import { ROLE_CATEGORIES, USER_STORIES } from "@/data/userStories";
import { getApiTopic } from "@/data/apiTopics";

interface BreadcrumbItem {
  label: string;
  path: string;
  icon?: React.ComponentType<{ className?: string }>;
}

export function Breadcrumbs() {
  const location = useLocation();

  const getBreadcrumbItems = (): BreadcrumbItem[] => {
    if (location.pathname === "/") {
      return [
        { label: "Playbook", path: "/", icon: Home },
        { label: "Project overview", path: "/" },
      ];
    }

    if (location.pathname === "/user-roles") {
      return [
        { label: "Playbook", path: "/", icon: Home },
        { label: "User roles", path: "/user-roles" },
      ];
    }

    const parts = location.pathname.split("/").filter(Boolean);
    const items: BreadcrumbItem[] = [{ label: "Playbook", path: "/", icon: Home }];

    if (parts[0] === "stories") {
      const roleId = parts[1];
      const storyId = parts[2];

      const roleObj = ROLE_CATEGORIES.find((r) => r.id === roleId);
      const roleName = roleObj ? roleObj.name : roleId ? roleId.charAt(0).toUpperCase() + roleId.slice(1) : "Stories";

      if (roleId) {
        items.push({
          label: roleName,
          path: `/stories/${roleId}`,
        });
      }

      if (storyId) {
        const story = USER_STORIES.find((s) => s.id === storyId);
        items.push({
          label: story ? `${story.id} (${story.functionality})` : storyId.toUpperCase(),
          path: `/stories/${roleId}/${storyId}`,
        });
      }
    }

    if (parts[0] === "api-spec") {
      items.push({
        label: "API specification",
        path: "/api-spec",
        icon: Code2,
      });

      const topicId = parts[1];
      if (topicId) {
        const topic = getApiTopic(topicId);
        items.push({
          label: topic ? topic.name : topicId,
          path: `/api-spec/${topicId}`,
        });
      }
    }

    return items;
  };

  const items = getBreadcrumbItems();

  return (
    <nav aria-label="Breadcrumb" className="flex items-center">
      <ol className="flex items-center gap-2 text-xs sm:text-sm">
        {items.map((item, index) => {
          const isLast = index === items.length - 1;
          const Icon = item.icon;

          return (
            <li key={item.path + index} className="flex items-center gap-2">
              {index > 0 && (
                <ChevronRight className="w-3.5 h-3.5 text-slate-400 shrink-0 select-none" />
              )}
              {isLast ? (
                <span className="font-semibold text-slate-900 truncate max-w-[200px] sm:max-w-[320px]">
                  {item.label}
                </span>
              ) : (
                <Link
                  to={item.path}
                  className="flex items-center gap-1.5 text-slate-500 hover:text-teal-700 font-medium transition-colors duration-150"
                >
                  {Icon && <Icon className="w-3.5 h-3.5 shrink-0 text-slate-400" />}
                  <span>{item.label}</span>
                </Link>
              )}
            </li>
          );
        })}
      </ol>
    </nav>
  );
}
