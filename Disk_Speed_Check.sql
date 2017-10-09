/*************************************************************************************************

Creator:    Rich Benner of RichBenner.com

File:       Disk_Speed_Check.sql

Summary:    Check how disks are performing

Adapted from David Pless's article: 
    https://blogs.msdn.microsoft.com/dpless/2010/12/01/leveraging-sys-dm_io_virtual_file_stats/


THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*************************************************************************************************/


SELECT 
      db_name(a.database_id) AS [DB Name]
    , b.name AS [DB File Name]
    , a.file_id AS [File ID]
    , CASE WHEN a.file_id = 2 THEN 'Log' ELSE 'Data' END AS [DB File Type]
    , UPPER(SUBSTRING(b.physical_name, 1, 2)) AS [Disk Location] 
    , CASE WHEN a.num_of_reads < 1 THEN NULL ELSE CAST(a.io_stall_read_ms/(a.num_of_reads) AS INT) END AS [Avg Read Stall]
    , CASE 
        WHEN CASE WHEN a.num_of_reads < 1 THEN NULL ELSE CAST(a.io_stall_read_ms/(a.num_of_reads) AS INT) END < 10 THEN 'Very Good'
        WHEN CASE WHEN a.num_of_reads < 1 THEN NULL ELSE CAST(a.io_stall_read_ms/(a.num_of_reads) AS INT) END < 20 THEN 'OK'
        WHEN CASE WHEN a.num_of_reads < 1 THEN NULL ELSE CAST(a.io_stall_read_ms/(a.num_of_reads) AS INT) END < 50 THEN 'Slow, Needs Attention'
        WHEN CASE WHEN a.num_of_reads < 1 THEN NULL ELSE CAST(a.io_stall_read_ms/(a.num_of_reads) AS INT) END >= 50 THEN 'Serious I/O Bottleneck'
        END AS [Read Performance]
    , a.num_of_reads AS [Num Reads]
    , CASE WHEN a.num_of_writes < 1 THEN NULL ELSE CAST(a.io_stall_write_ms/a.num_of_writes AS INT) END AS [Avg_Write_Stall]
    , CASE 
        WHEN CASE WHEN a.num_of_writes < 1 THEN NULL ELSE CAST(a.io_stall_write_ms/(a.num_of_writes) AS INT) END < 10 THEN 'Very Good'
        WHEN CASE WHEN a.num_of_writes < 1 THEN NULL ELSE CAST(a.io_stall_write_ms/(a.num_of_writes) AS INT) END < 20 THEN 'OK'
        WHEN CASE WHEN a.num_of_writes < 1 THEN NULL ELSE CAST(a.io_stall_write_ms/(a.num_of_writes) AS INT) END < 50 THEN 'Slow, Needs Attention'
        WHEN CASE WHEN a.num_of_writes < 1 THEN NULL ELSE CAST(a.io_stall_write_ms/(a.num_of_writes) AS INT) END >= 50 THEN 'Serious I/O Bottleneck'
        END AS [Write Performance]
    , a.num_of_writes AS [Num Writes]
    , CAST(((a.size_on_disk_bytes/1024)/1024.0)/1024 AS DECIMAL(10,2)) AS [Size on Disk GB]
FROM sys.dm_io_virtual_file_stats (NULL, NULL) a 
JOIN sys.master_files b 
    ON a.file_id = b.file_id 
    AND a.database_id = b.database_id 
ORDER BY (a.num_of_reads + a.num_of_writes) DESC
