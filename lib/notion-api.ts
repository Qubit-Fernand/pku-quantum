import { NotionAPI } from 'notion-client'

const notionUserAgent =
  'Mozilla/5.0 (compatible; pku-quantum/1.0; +https://pku-quantum.tech)'

function normalizeRecordMap(recordMap) {
  if (!recordMap) {
    return recordMap
  }

  for (const table of ['block', 'collection', 'collection_view', 'notion_user']) {
    const records = recordMap[table]
    if (!records) {
      continue
    }

    for (const [id, record] of Object.entries(records)) {
      const value = (record as any)?.value
      if (value?.value) {
        const spaceId = (record as any).spaceId ?? value.spaceId
        records[id] =
          spaceId === undefined
            ? value
            : {
                ...value,
                spaceId
              }
      }
    }
  }

  return recordMap
}

function normalizeNotionResponse(response) {
  if (response?.recordMap) {
    response.recordMap = normalizeRecordMap(response.recordMap)
  }

  return response
}

const notionApi = new NotionAPI({
  apiBaseUrl: process.env.NOTION_API_BASE_URL
})

const notionFetch = notionApi.fetch.bind(notionApi)
notionApi.fetch = (async (args) => {
  const gotOptions = args.gotOptions || {}
  const response = await notionFetch({
    ...args,
    gotOptions: {
      ...gotOptions,
      headers: {
        'User-Agent': notionUserAgent,
        ...gotOptions.headers
      }
    }
  })

  return normalizeNotionResponse(response)
}) as typeof notionApi.fetch

export const notion = notionApi
