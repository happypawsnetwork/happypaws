import { useState, useEffect, useMemo } from 'react';
import { useLocation, useParams, useNavigate, Link } from 'react-router';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Search,
  ChevronDown,
  Copy,
  Check,
  Code2,
  Filter,
  Layers,
  Sparkles,
  ExternalLink,
  ArrowLeft
} from 'lucide-react';
import {
  allApiOperations,
  openApiSpecInfo,
  getMethodBadgeClasses,
  type ApiOperation
} from '@/data/openApiUtils';
import { getApiTopic, API_TOPICS } from '@/data/apiTopics';
import { IconMap } from '@/components/Icons';

export function ApiSpecPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const { topicId } = useParams<{ topicId?: string }>();
  const activeTopic = topicId ? getApiTopic(topicId) : undefined;

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedMethod, setSelectedMethod] = useState<string>('ALL');
  const [expandedEndpoints, setExpandedEndpoints] = useState<Record<string, boolean>>({});
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const activeHash = location.hash.replace(/^#/, '').toLowerCase();

  // Smooth scroll to target endpoint on hash change
  useEffect(() => {
    if (!activeHash) return;

    const timer = setTimeout(() => {
      const el = document.getElementById(activeHash);
      if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
    }, 120);

    return () => clearTimeout(timer);
  }, [activeHash]);

  const toggleExpand = (id: string) => {
    setExpandedEndpoints(prev => {
      const current = prev[id] ?? (activeHash === id.toLowerCase());
      return {
        ...prev,
        [id]: !current
      };
    });
  };

  const copyEndpoint = (op: ApiOperation, e: React.MouseEvent) => {
    e.stopPropagation();
    const curl = `curl -X ${op.method} "https://api.happypaws.lk${op.path}"`;
    navigator.clipboard.writeText(curl);
    setCopiedId(op.id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  // Filter operations based on query, method, and active topic
  const filteredOperations = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    const baseOperations = activeTopic ? activeTopic.endpoints : allApiOperations;

    return baseOperations.filter(op => {
      const matchesSearch =
        !q ||
        op.path.toLowerCase().includes(q) ||
        op.summary.toLowerCase().includes(q) ||
        op.description.toLowerCase().includes(q) ||
        op.category.toLowerCase().includes(q) ||
        op.operationId.toLowerCase().includes(q);

      const matchesMethod = selectedMethod === 'ALL' || op.method === selectedMethod;

      return matchesSearch && matchesMethod;
    });
  }, [activeTopic, searchQuery, selectedMethod]);

  // Group filtered operations by category
  const groupedOperations = useMemo(() => {
    const map: Record<string, ApiOperation[]> = {};
    for (const op of filteredOperations) {
      if (!map[op.category]) {
        map[op.category] = [];
      }
      map[op.category].push(op);
    }
    return map;
  }, [filteredOperations]);

  const methodsList = ['ALL', 'GET', 'POST', 'PUT', 'PATCH', 'DELETE'];
  const TopicIcon = activeTopic ? IconMap[activeTopic.iconName] || Code2 : Code2;

  return (
    <div className="space-y-8 pb-16">
      {/* Header Banner */}
      <div className="bg-white p-6 md:p-8 rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="space-y-1.5">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-lg bg-teal-50 border border-teal-200 flex items-center justify-center text-teal-700">
                <TopicIcon className="w-4 h-4" />
              </div>
              <h1 className="text-2xl font-bold text-slate-900 tracking-tight">
                {activeTopic ? activeTopic.name : 'REST API Specification'}
              </h1>
            </div>
            <p className="text-xs md:text-sm text-slate-500 leading-relaxed max-w-2xl">
              {activeTopic
                ? activeTopic.description
                : 'Complete OpenAPI 3.1 specification for the backend API (ASP.NET Core 10). Interactive schema explorer with real-time route inspection, parameters, and payloads.'}
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            {activeTopic && (
              <Link
                to="/api-spec"
                className="text-xs font-medium px-2.5 py-1 rounded-md bg-slate-50 hover:bg-slate-100 text-slate-600 border border-slate-200 transition flex items-center gap-1.5"
              >
                <ArrowLeft className="w-3.5 h-3.5" />
                All topics
              </Link>
            )}
            <span className="text-xs font-mono font-semibold px-2.5 py-1 rounded-md bg-teal-50 text-teal-800 border border-teal-200/80">
              OpenAPI {openApiSpecInfo.openapi}
            </span>
            <span className="text-xs font-mono font-semibold px-2.5 py-1 rounded-md bg-slate-100 text-slate-700 border border-slate-200/80">
              {activeTopic ? activeTopic.endpointCount : allApiOperations.length} operations
            </span>
          </div>
        </div>

        {/* Search & Filter Controls */}
        <div className="pt-4 border-t border-slate-100 grid grid-cols-1 md:grid-cols-12 gap-3">
          {/* Keyword Search */}
          <div className="relative md:col-span-6">
            <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              type="text"
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
              placeholder="Filter by path, summary, or keyword (e.g. /posts, rescues)..."
              className="w-full pl-9 pr-3.5 py-2 rounded-xl text-xs md:text-sm border border-slate-200 bg-slate-50/50 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 focus:bg-white transition"
            />
          </div>

          {/* Topic Switcher Dropdown */}
          <div className="relative md:col-span-6 flex items-center gap-2">
            <div className="relative w-full">
              <Layers className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              <select
                value={activeTopic?.id || 'ALL'}
                onChange={e => {
                  const val = e.target.value;
                  if (val === 'ALL') {
                    navigate('/api-spec');
                  } else {
                    navigate(`/api-spec/${val}`);
                  }
                }}
                className="w-full pl-9 pr-8 py-2 rounded-xl text-xs md:text-sm border border-slate-200 bg-slate-50/50 text-slate-700 focus:outline-none focus:ring-2 focus:ring-teal-500 focus:bg-white transition appearance-none cursor-pointer"
              >
                <option value="ALL">All topics ({allApiOperations.length} operations)</option>
                {API_TOPICS.map(topic => (
                  <option key={topic.id} value={topic.id}>
                    {topic.name} ({topic.endpointCount})
                  </option>
                ))}
              </select>
              <ChevronDown className="w-3.5 h-3.5 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
            </div>
          </div>
        </div>

        {/* Method Pills */}
        <div className="pt-2 flex flex-wrap items-center gap-1.5">
          <span className="text-xs font-semibold text-slate-400 mr-2 flex items-center gap-1">
            <Filter className="w-3 h-3" /> Method:
          </span>
          {methodsList.map(method => {
            const baseList = activeTopic ? activeTopic.endpoints : allApiOperations;
            const count =
              method === 'ALL'
                ? baseList.length
                : baseList.filter(op => op.method === method).length;

            const isSelected = selectedMethod === method;

            return (
              <button
                key={method}
                onClick={() => setSelectedMethod(method)}
                className={`px-2.5 py-1 rounded-lg text-xs font-medium font-mono transition cursor-pointer ${
                  isSelected
                    ? 'bg-slate-900 text-white shadow-xs font-semibold'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200/80'
                }`}
              >
                {method} <span className="text-[10px] opacity-75">({count})</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Operations List Grouped by Category */}
      {Object.keys(groupedOperations).length > 0 ? (
        <div className="space-y-8">
          {Object.entries(groupedOperations).map(([category, operations]) => (
            <div key={category} className="space-y-3">
              {/* Category Header */}
              <div className="flex items-center justify-between pb-1.5 border-b border-slate-200">
                <h2 className="text-sm font-bold uppercase tracking-wider text-slate-600 flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-teal-500" />
                  {category}
                </h2>
                <span className="text-xs font-mono font-medium text-slate-400">
                  {operations.length} {operations.length === 1 ? 'operation' : 'operations'}
                </span>
              </div>

              {/* Endpoints in Category */}
              <div className="space-y-2.5">
                {operations.map(op => {
                  const isExpanded = expandedEndpoints[op.id] ?? (activeHash === op.id.toLowerCase());
                  const isHighlighted = activeHash === op.id.toLowerCase();
                  const isCopied = copiedId === op.id;
                  const styling = getMethodBadgeClasses(op.method);

                  return (
                    <div
                      key={op.id}
                      id={op.id}
                      className={`bg-white rounded-xl border transition-all duration-300 overflow-hidden ${
                        isHighlighted
                          ? 'ring-2 ring-teal-500 border-teal-500 shadow-md bg-teal-50/20'
                          : isExpanded
                          ? 'border-slate-300 shadow-xs'
                          : 'border-slate-200/80 hover:border-slate-300'
                      }`}
                    >
                      {/* Operation Row Header */}
                      <div
                        onClick={() => toggleExpand(op.id)}
                        className="p-3.5 md:p-4 flex items-center justify-between gap-3 cursor-pointer select-none group"
                      >
                        <div className="flex items-center gap-3 min-w-0 flex-1">
                          {/* Method Pill */}
                          <span
                            className={`px-2.5 py-1 rounded-md text-[11px] font-mono font-bold border shrink-0 ${styling.badge}`}
                          >
                            {op.method}
                          </span>

                          {/* Path with highlighted route params */}
                          <span className="font-mono text-xs md:text-sm font-medium text-slate-800 truncate">
                            {op.path.split(/({[^}]+})/).map((part, idx) =>
                              part.startsWith('{') && part.endsWith('}') ? (
                                <span key={idx} className="text-amber-700 font-semibold bg-amber-50 px-1 py-0.5 rounded">
                                  {part}
                                </span>
                              ) : (
                                <span key={idx}>{part}</span>
                              )
                            )}
                          </span>

                          {/* Summary */}
                          <span className="hidden lg:inline text-xs text-slate-400 truncate max-w-sm">
                            &bull; {op.summary}
                          </span>
                        </div>

                        {/* Actions */}
                        <div className="flex items-center gap-2 shrink-0">
                          {isHighlighted && (
                            <span className="hidden sm:inline-flex items-center gap-1 text-[11px] font-medium text-teal-700 bg-teal-50 px-2 py-0.5 rounded-full border border-teal-200">
                              <Sparkles className="w-3 h-3 text-teal-600" /> Matching story
                            </span>
                          )}

                          <button
                            type="button"
                            title="Copy cURL snippet"
                            onClick={e => copyEndpoint(op, e)}
                            className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition cursor-pointer"
                          >
                            {isCopied ? (
                              <Check className="w-3.5 h-3.5 text-emerald-600" />
                            ) : (
                              <Copy className="w-3.5 h-3.5" />
                            )}
                          </button>

                          <div className="w-6 h-6 rounded-md flex items-center justify-center text-slate-400 group-hover:text-slate-600 transition">
                            <ChevronDown
                              className={`w-4 h-4 transition-transform duration-200 ${
                                isExpanded ? 'rotate-180 text-teal-600' : ''
                              }`}
                            />
                          </div>
                        </div>
                      </div>

                      {/* Expandable Details Container */}
                      <AnimatePresence initial={false}>
                        {isExpanded && (
                          <motion.div
                            initial={{ height: 0, opacity: 0 }}
                            animate={{ height: 'auto', opacity: 1 }}
                            exit={{ height: 0, opacity: 0 }}
                            transition={{ duration: 0.2 }}
                            className="border-t border-slate-100 bg-slate-50/50 px-4 py-5 md:px-6 md:py-6 space-y-5 text-xs"
                          >
                            {/* Description & Operation ID */}
                            <div className="space-y-1.5">
                              <div className="flex items-center justify-between">
                                <span className="font-semibold text-slate-700">Description</span>
                                <span className="text-[11px] font-mono text-slate-400">
                                  ID: {op.operationId}
                                </span>
                              </div>
                              <p className="text-slate-600 leading-relaxed">
                                {op.description || op.summary || 'No detailed description provided.'}
                              </p>
                            </div>

                            {/* Parameters Section */}
                            {op.parameters && op.parameters.length > 0 && (
                              <div className="space-y-2">
                                <span className="font-semibold text-slate-700 uppercase tracking-wider text-[11px]">
                                  Parameters
                                </span>
                                <div className="border border-slate-200 rounded-xl overflow-hidden bg-white shadow-2xs">
                                  <table className="w-full text-left border-collapse">
                                    <thead>
                                      <tr className="bg-slate-50/80 text-[11px] text-slate-500 font-semibold border-b border-slate-200">
                                        <th className="p-2.5">Name</th>
                                        <th className="p-2.5">Location</th>
                                        <th className="p-2.5">Type</th>
                                        <th className="p-2.5">Required</th>
                                        <th className="p-2.5">Description</th>
                                      </tr>
                                    </thead>
                                    <tbody className="divide-y divide-slate-100 font-mono text-[11px]">
                                      {op.parameters.map((param, pIdx) => (
                                        <tr key={pIdx} className="hover:bg-slate-50/50">
                                          <td className="p-2.5 font-bold text-slate-800">
                                            {param.name}
                                          </td>
                                          <td className="p-2.5 text-slate-500">
                                            <span className="px-1.5 py-0.5 rounded bg-slate-100 text-slate-700">
                                              {param.in}
                                            </span>
                                          </td>
                                          <td className="p-2.5 text-teal-700">
                                            {param.schema?.type || 'string'}
                                          </td>
                                          <td className="p-2.5">
                                            {param.required ? (
                                              <span className="text-rose-600 font-semibold">Yes</span>
                                            ) : (
                                              <span className="text-slate-400">No</span>
                                            )}
                                          </td>
                                          <td className="p-2.5 font-sans text-slate-600">
                                            {param.description || 'None'}
                                          </td>
                                        </tr>
                                      ))}
                                    </tbody>
                                  </table>
                                </div>
                              </div>
                            )}

                            {/* Request Body Section */}
                            {op.requestBody && (
                              <div className="space-y-2">
                                <div className="flex items-center justify-between">
                                  <span className="font-semibold text-slate-700 uppercase tracking-wider text-[11px]">
                                    Request Body (JSON)
                                  </span>
                                  {op.requestBody.required && (
                                    <span className="text-[11px] text-rose-600 font-semibold">
                                      Required
                                    </span>
                                  )}
                                </div>
                                <div className="p-3.5 rounded-xl bg-slate-900 text-slate-200 font-mono text-[11px] overflow-x-auto">
                                  <pre className="leading-relaxed">
                                    {JSON.stringify(
                                      op.requestBody.content?.['application/json']?.schema || {},
                                      null,
                                      2
                                    )}
                                  </pre>
                                </div>
                              </div>
                            )}

                            {/* Responses Section */}
                            <div className="space-y-2">
                              <span className="font-semibold text-slate-700 uppercase tracking-wider text-[11px]">
                                Responses
                              </span>
                              <div className="border border-slate-200 rounded-xl overflow-hidden bg-white shadow-2xs divide-y divide-slate-100">
                                {Object.entries(op.responses).map(([code, resp]) => {
                                  const isSuccess = code.startsWith('2');
                                  const isClientError = code.startsWith('4');

                                  return (
                                    <div key={code} className="p-3 flex items-start gap-3">
                                      <span
                                        className={`px-2 py-0.5 rounded font-mono font-bold text-[11px] shrink-0 ${
                                          isSuccess
                                            ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                            : isClientError
                                            ? 'bg-amber-50 text-amber-700 border border-amber-200'
                                            : 'bg-slate-100 text-slate-700 border border-slate-200'
                                        }`}
                                      >
                                        HTTP {code}
                                      </span>
                                      <div className="flex-1 min-w-0">
                                        <p className="text-slate-700 font-medium font-sans text-xs">
                                          {resp.description || 'Response payload'}
                                        </p>
                                        {resp.content?.['application/json']?.schema && (
                                          <p className="text-slate-400 font-mono text-[10px] mt-0.5 truncate">
                                            Schema: {JSON.stringify(resp.content['application/json'].schema)}
                                          </p>
                                        )}
                                      </div>
                                    </div>
                                  );
                                })}
                              </div>
                            </div>

                            {/* Anchor Link Copy */}
                            <div className="pt-2 flex items-center justify-between text-slate-400 text-[11px]">
                              <span className="font-mono">Anchor: #{op.id}</span>
                              <a
                                href={`#${op.id}`}
                                className="inline-flex items-center gap-1 text-teal-600 hover:text-teal-800 transition"
                              >
                                Direct link <ExternalLink className="w-3 h-3" />
                              </a>
                            </div>
                          </motion.div>
                        )}
                      </AnimatePresence>
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="bg-white p-12 rounded-2xl border border-slate-200/80 text-center space-y-3">
          <Code2 className="w-10 h-10 text-slate-300 mx-auto" />
          <p className="text-sm font-semibold text-slate-700">No matching API operations found</p>
          <p className="text-xs text-slate-400">
            Try adjusting your search query, selecting another HTTP method, or choosing a different category.
          </p>
        </div>
      )}
    </div>
  );
}
